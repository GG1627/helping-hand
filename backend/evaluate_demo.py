"""Prepare model predictions and replay recorded attempts through actual Flutter rules.

No training, threshold tuning, or deployment. Reports are offline diagnostics.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

try:
    from .sequence_preprocessing import SequencePreprocessing
    from .word_data import load_recording, resample_trial, fixed_window
    from .word_dataset import SequenceStandardizer
except ImportError:
    from sequence_preprocessing import SequencePreprocessing
    from word_data import load_recording, resample_trial, fixed_window
    from word_dataset import SequenceStandardizer

ROOT = Path(__file__).resolve().parents[1]


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


class ModelRuntime:
    def __init__(self, directory, mode):
        import numpy as np
        import tensorflow as tf
        self.np = np
        self.metadata = read_json(directory / ("metadata.json" if mode == "static" else "model_metadata.json"))
        self.labels = self.metadata["classes" if mode == "static" else "vocabulary"]
        if len(set(self.labels)) != len(self.labels) or len(self.labels) < 2:
            raise ValueError("Model labels must be unique")
        self.runtime = tf.lite.Interpreter(model_path=str(directory / "model.tflite"), num_threads=1)
        self.runtime.allocate_tensors()
        self.input = self.runtime.get_input_details()[0]
        self.output = self.runtime.get_output_details()[0]
        self.config = None if mode == "static" else SequencePreprocessing.from_metadata(self.metadata)
        shape = [1, 5] if mode == "static" else [1, self.config.window_samples, len(self.config.feature_columns)]
        if (self.input['shape'].tolist() != shape or self.output['shape'].tolist() != [1, len(self.labels)]
                or self.input['dtype'] != np.float32 or self.output['dtype'] != np.float32):
            raise ValueError("Unexpected model tensor contract")
        self.evidence = {"directory": str(directory), "model_sha256": digest(directory / "model.tflite"),
                         "metadata_sha256": digest(directory / ("metadata.json" if mode == "static" else "model_metadata.json"))}
        split = self.metadata.get('split_manifest')
        if split is None and (directory / 'split_manifest.json').exists():
            split = read_json(directory / 'split_manifest.json')
        assignments = (split or {}).get('assignments', {})
        self.splits = assignments if isinstance(assignments, dict) else {
            item['session_id'] + '/' + item['trial_id']: item['split'] for item in assignments}

    def predict(self, values):
        np = self.np
        self.runtime.set_tensor(self.input['index'], np.asarray(values, dtype=np.float32)[None])
        self.runtime.invoke()
        scores = self.runtime.get_tensor(self.output['index'])[0]
        if not np.isfinite(scores).all() or (scores < 0).any() or not np.isclose(scores.sum(), 1, atol=1e-4):
            raise ValueError("Invalid probability vector")
        return scores

    def static_predictions(self, rows):
        np = self.np
        try:
            from .train_static_recorded import calibrate
        except ImportError:
            from train_static_recorded import calibrate
        from_keys = ['flex_' + name + '_raw' for name in ('thumb', 'index', 'middle', 'ring', 'pinky')]
        config = self.metadata['calibration']
        if self.metadata.get('feature_cols') != from_keys:
            raise ValueError('Unsupported static feature order')
        mean, scale = np.float32(self.metadata['mean']), np.float32(self.metadata['scale'])
        if mean.shape != (5,) or scale.shape != (5,) or not np.isfinite(mean).all() or not np.isfinite(scale).all() or (scale <= 0).any():
            raise ValueError('Invalid static scaler')
        predictions = []
        for row in rows:
            try:
                values = np.asarray([float(row[key]) for key in from_keys], dtype=np.float32)
                if not np.isfinite(values).all() or (values < 0).any() or (values > 4095).any():
                    raise ValueError('Invalid flex values')
                values = calibrate(values[None], config)[0]
                scores = self.predict((values - mean) / scale)
                fields = {}
                for category, indexes in [('pred', list(range(len(self.labels)))),
                        ('pred_letter', [i for i, label in enumerate(self.labels) if len(label) == 1 and 'A' <= label <= 'Z']),
                        ('pred_number', [i for i, label in enumerate(self.labels) if len(label) == 1 and label.isdigit()])]:
                    best = max(indexes, key=lambda i: scores[i]) if indexes else None
                    fields[category] = self.labels[best] if best is not None else 'NA'
                    fields[category + '_conf'] = format(float(np.float32(scores[best] * np.float32(100))), '.1f') if best is not None else '0.0'
                predictions.append(fields)
            except (KeyError, TypeError, ValueError):
                # Never let the source firmware prediction stand in for a failed candidate.
                predictions.append({'pred': 'NA', 'pred_conf': '0.0', 'pred_letter': 'NA',
                                    'pred_letter_conf': '0.0', 'pred_number': 'NA', 'pred_number_conf': '0.0'})
        return predictions


def prepare_plan(plan_path: Path, *, static_bundle=None, word_bundle=None):
    plan = read_json(plan_path)
    if plan.get('schema_version') != 'demo-evaluation-plan-v1':
        raise ValueError('Unsupported evaluation plan')
    mode = plan.get('mode')
    targets = plan.get('targets')
    origin = plan.get('data_origin')
    timing = plan.get('timing', 'recorded_receive')
    if mode not in {'static', 'word'} or origin not in {'real', 'synthetic_fixture'}:
        raise ValueError('Declare mode and data_origin')
    if (mode == 'word' and static_bundle) or (mode == 'static' and word_bundle):
        raise ValueError('Bundle option does not match the selected evaluation mode')
    if timing not in {'recorded_receive', 'simulated_device'}:
        raise ValueError('Unsupported timing policy')
    if not isinstance(targets, list) or not targets or len(set(targets)) != len(targets):
        raise ValueError('Declare unique target labels')
    allowed = lambda target: isinstance(target, str) and ((len(target) == 1 and target in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789') if mode == 'static' else target in ('hello', 'please', 'yes'))
    if not all(allowed(t) for t in targets):
        raise ValueError('Unsupported practice target')
    if not isinstance(plan.get('trials'), list) or not plan['trials']:
        raise ValueError('List independent recording trials to replay')
    model = ModelRuntime(static_bundle, mode) if mode == 'static' and static_bundle else (
        ModelRuntime(word_bundle or ROOT / 'flutter_app/assets/models/words_tcn', mode) if mode == 'word' else None)
    prepared, sources, seen = [], {}, set()
    for item in plan['trials']:
        source = (plan_path.parent / item['csv']).resolve()
        manifest_path = (plan_path.parent / item['manifest']).resolve() if item.get('manifest') else source.with_name('manifest.json')
        manifest = read_json(manifest_path)
        if manifest.get('data_origin') != origin:
            raise ValueError('Plan origin must match every source manifest')
        # Identical logical trials from a copied CSV are not independent trials.
        logical = (item['session_id'], item['trial_id'])
        if logical in seen:
            raise ValueError('Duplicate trial identity')
        seen.add(logical)
        kind = item.get('kind')
        label = item.get('performed_label')
        if kind not in {'sign', 'idle', 'incomplete', 'unrelated'} or (kind == 'sign' and (not isinstance(label, str) or not label.strip())):
            raise ValueError('Each trial needs a kind and sign trials need performed_label')
        if kind == 'sign' and mode == 'static' and not allowed(label):
            raise ValueError('Static performed_label must use uppercase A-Z or a digit')
        with source.open(encoding='utf-8', newline='') as handle:
            rows = [row for row in csv.DictReader(handle) if row['session_id'] == item['session_id'] and row['trial_id'] == item['trial_id']]
        if not rows or [int(r['sample_index']) for r in rows] != list(range(len(rows))):
            raise ValueError('Trial missing or sample ordering is invalid')
        received = [int(row['receive_timestamp_ms']) for row in rows]
        devices = [int(row['device_timestamp_ms']) for row in rows]
        replay_times = received if timing == 'recorded_receive' else [received[0] + t - devices[0] for t in devices]
        if ('start_ms' in item) != ('finish_ms' in item):
            raise ValueError('Supply both explicit start_ms and finish_ms, or neither')
        trial = {'trial_key': '/'.join(logical), 'kind': kind, 'performed_label': label,
                 'model_split': model.splits.get('/'.join(logical), 'not_in_training_manifest') if model else 'unknown_original_firmware',
                 'packets': [{'raw_packet': row['raw_packet'], 'received_ms': t} for row, t in zip(rows, replay_times)],
                 'start_ms': item.get('start_ms', replay_times[0] - 1),
                 'finish_ms': item.get('finish_ms', max(replay_times) + 1),
                 'boundary_source': 'operator_supplied' if 'start_ms' in item and 'finish_ms' in item else 'constructed_one_ms_around_recorded_packets',
                 'duplicate_receive_timestamps': len(received) - len(set(received))}
        if (any(type(trial[key]) is not int for key in ('start_ms', 'finish_ms'))
                or trial['finish_ms'] < trial['start_ms']):
            raise ValueError('Capture bounds must be integer milliseconds with finish >= start')
        if mode == 'static' and model:
            for row, packet, override in zip(rows, trial['packets'], model.static_predictions(rows)):
                packet['prediction_override'] = override
                packet['candidate_flex_raw'] = [row['flex_' + f + '_raw'] for f in ('thumb', 'index', 'middle', 'ring', 'pinky')]
        elif mode == 'word':
            try:
                recording = load_recording(source, manifest_path=manifest_path)
                if not recording.report.is_valid:
                    raise ValueError('Source recording validation failed')
                samples = recording.trials()[logical]
                if trial['boundary_source'] == 'operator_supplied':
                    selected = {int(row['sample_index']) for row, timestamp in zip(rows, replay_times)
                                if trial['start_ms'] <= timestamp <= trial['finish_ms']}
                    samples = tuple(sample for sample in samples if sample.sample_index in selected)
                sequence = resample_trial(samples, target_rate_hz=model.config.target_rate_hz, feature_columns=model.config.feature_columns)
                model.config.check_capture_length(len(sequence.values))
                window = fixed_window(sequence, window_size=model.config.window_samples, window_policy=model.config.window_policy)
                scaler = SequenceStandardizer.from_dict(model.metadata['standardizer'])
                tensor = scaler.transform(window.values)
                trial['probabilities'] = model.predict(tensor).tolist()
                trial['prepared_input'] = tensor.tolist()
            except (KeyError, TypeError, ValueError) as error:
                trial['prediction_error'] = str(error)
        sources[str(source)] = {'csv_sha256': digest(source), 'manifest_sha256': digest(manifest_path)}
        prepared.append(trial)
    return {'schema_version': 'demo-replay-input-v1', 'mode': mode, 'targets': targets,
            'data_origin': origin, 'timing': timing, 'trials': prepared, 'sources': sources,
            'model': model.evidence if model else {'source': 'predictions_in_original_raw_packets'},
            'word_metadata': model.metadata if mode == 'word' else None,
            'plan_sha256': digest(plan_path), 'result_scope': 'offline_rules_replay',
            'hardware_validation': 'Not run', 'final_accuracy_claim_ready': False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('plan', type=Path)
    parser.add_argument('--output-directory', type=Path, required=True)
    parser.add_argument('--static-bundle', type=Path)
    parser.add_argument('--word-bundle', type=Path)
    parser.add_argument('--prepare-only', action='store_true')
    args = parser.parse_args()
    output = args.output_directory.resolve()
    if output.exists():
        parser.error('Use a new output directory to preserve old reports')
    try:
        replay = prepare_plan(args.plan.resolve(), static_bundle=args.static_bundle, word_bundle=args.word_bundle)
        output.mkdir(parents=True)
        replay_path = output / 'replay_input.json'
        replay_path.write_text(json.dumps(replay, indent=2, allow_nan=False) + '\n', encoding='utf-8')
        if args.prepare_only:
            print(f'Prepared replay input only: {replay_path}')
            return
        flutter = shutil.which('flutter')
        if not flutter:
            raise ValueError('Flutter is required for actual-rule replay')
        cache = Path(flutter).resolve().parent / 'cache'
        dart = cache / 'dart-sdk/bin' / ('dart.exe' if Path(flutter).suffix.lower() == '.bat' else 'dart')
        # Invoke the SDK executable directly, avoiding a shell/batch command.
        subprocess.run([str(dart), str(cache / 'flutter_tools.snapshot'), 'test', '--no-pub',
                        'test/demo_evaluation_test.dart',
                        f'--dart-define=HH_DEMO_INPUT={replay_path}',
                        f'--dart-define=HH_DEMO_OUTPUT={output / "report.json"}'],
                       cwd=ROOT / 'flutter_app', check=True)
        print(f'Offline report: {output / "report.json"}')
    except (OSError, KeyError, TypeError, ValueError, subprocess.CalledProcessError) as error:
        parser.exit(1, f'Evaluation failed: {error}\n')


if __name__ == '__main__':
    main()
