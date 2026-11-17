$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$outputDir = Join-Path (Get-Location) 'docs/figures/r3'
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
$width = 1800
$height = 1280
$bitmap = [System.Drawing.Bitmap]::new($width, $height)
$bitmap.SetResolution(300, 300)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.Clear([System.Drawing.Color]::White)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$svg = [System.Collections.Generic.List[string]]::new()
$cells = [System.Collections.Generic.List[string]]::new()
$svg.Add('<svg xmlns="http://www.w3.org/2000/svg" width="1800" height="1280" viewBox="0 0 1800 1280"><title>Helping Hand implemented system and planned hardware integration</title><desc>Flex sensors and a six-axis IMU feed ESP32 static recognition. BLE connects the ESP32 to the Flutter app with word inference and local progress. HTTPS connects the phone to Firebase. Dashed elements show a planned nine-axis replacement IMU, piezo drivers, correction-to-cue logic, and an unfabricated custom PCB replacing perfboard.</desc><rect width="1800" height="1280" fill="white"/>')
$cells.Add('<mxCell id="0"/><mxCell id="1" parent="0"/>')
function Esc([string]$value) { return [System.Security.SecurityElement]::Escape($value) }
function Add-Text {
    param([string]$Id,[string]$Text,[float]$X,[float]$Y,[float]$W,[float]$H,[float]$Size=30,[bool]$Bold=$false,[string]$Color='#202020',[string]$Align='Center')
    $fontStyle = if ($Bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
    $font = [System.Drawing.Font]::new('Arial',$Size,$fontStyle,[System.Drawing.GraphicsUnit]::Pixel)
    $brush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($Color))
    $format = [System.Drawing.StringFormat]::new()
    $format.Alignment = if ($Align -eq 'Left') { [System.Drawing.StringAlignment]::Near } else { [System.Drawing.StringAlignment]::Center }
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    $format.FormatFlags = [System.Drawing.StringFormatFlags]::NoWrap
    $rect = [System.Drawing.RectangleF]::new($X,$Y,$W,$H)
    $graphics.DrawString($Text,$font,$brush,$rect,$format)
    $anchor = if ($Align -eq 'Left') {'start'} else {'middle'}
    $textX = if ($Align -eq 'Left') {$X} else {$X+$W/2}
    $textY = $Y+$H/2+$Size*0.35
    $weight = if ($Bold) {'700'} else {'400'}
    $svg.Add("<text x='$textX' y='$textY' font-family='Arial,Helvetica,sans-serif' font-size='$Size' font-weight='$weight' text-anchor='$anchor' fill='$Color'>$(Esc $Text)</text>")
    $styleBold = if ($Bold) {1} else {0}
    $alignStyle = if ($Align -eq 'Left') {'left'} else {'center'}
    $cells.Add("<mxCell id='$Id' value='$(Esc $Text)' style='text;html=0;strokeColor=none;fillColor=none;align=$alignStyle;verticalAlign=middle;whiteSpace=wrap;fontFamily=Arial;fontSize=$Size;fontStyle=$styleBold;fontColor=$Color;' vertex='1' parent='1'><mxGeometry x='$X' y='$Y' width='$W' height='$H' as='geometry'/></mxCell>")
    $measured = $graphics.MeasureString($Text,$font)
    if ($measured.Width -gt ($W+10)) { Write-Warning "Text may exceed box: $Text ($($measured.Width) > $W)" }
    $format.Dispose(); $brush.Dispose(); $font.Dispose()
}
function Add-Box {
    param([string]$Id,[float]$X,[float]$Y,[float]$W,[float]$H,[string]$Fill='#dae8fc',[string]$Stroke='#6c8ebf',[bool]$Dashed=$false,[string[]]$Lines=@())
    $brush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($Fill))
    $pen = [System.Drawing.Pen]::new([System.Drawing.ColorTranslator]::FromHtml($Stroke),2.5)
    if ($Dashed) { $pen.DashPattern = [float[]]@(5,3) }
    $graphics.FillRectangle($brush,$X,$Y,$W,$H)
    $graphics.DrawRectangle($pen,$X,$Y,$W,$H)
    $dashSvg = if ($Dashed) {"stroke-dasharray='12 8'"} else {''}
    $svg.Add("<rect x='$X' y='$Y' width='$W' height='$H' fill='$Fill' stroke='$Stroke' stroke-width='2.5' $dashSvg/>")
    $dashStyle = if ($Dashed) {'dashed=1;dashPattern=5 3;'} else {''}
    $cells.Add("<mxCell id='$Id' value='' style='rounded=0;whiteSpace=wrap;html=0;fillColor=$Fill;strokeColor=$Stroke;strokeWidth=2.5;$dashStyle' vertex='1' parent='1'><mxGeometry x='$X' y='$Y' width='$W' height='$H' as='geometry'/></mxCell>")
    $lineHeight = 38
    $startY = $Y + ($H - $Lines.Count*$lineHeight)/2
    for ($i=0; $i -lt $Lines.Count; $i++) {
        Add-Text -Id "$Id-text-$i" -Text $Lines[$i] -X ($X+8) -Y ($startY+$i*$lineHeight) -W ($W-16) -H $lineHeight -Size 30 -Bold ($i -eq 0)
    }
    $brush.Dispose(); $pen.Dispose()
}
function Add-Line {
    param([string]$Id,[double[][]]$Points,[bool]$Dashed=$false,[bool]$Arrow=$true,[string]$Color='#404040')
    $pen = [System.Drawing.Pen]::new([System.Drawing.ColorTranslator]::FromHtml($Color),3)
    if ($Dashed) { $pen.DashPattern = [float[]]@(5,3) }
    $gdiPoints = [System.Drawing.PointF[]]@($Points | ForEach-Object { [System.Drawing.PointF]::new($_[0],$_[1]) })
    $graphics.DrawLines($pen,$gdiPoints)
    $pointString = ($Points | ForEach-Object {"$($_[0]),$($_[1])"}) -join ' '
    $dashSvg = if ($Dashed) {"stroke-dasharray='12 8'"} else {''}
    $svg.Add("<polyline points='$pointString' fill='none' stroke='$Color' stroke-width='3' $dashSvg/>")
    if ($Arrow) {
        $tip = $Points[-1]; $prev = $Points[-2]
        $angle = [Math]::Atan2($tip[1]-$prev[1],$tip[0]-$prev[0])
        $baseX = $tip[0]-16*[Math]::Cos($angle)
        $baseY = $tip[1]-16*[Math]::Sin($angle)
        $arrowPoints = [System.Drawing.PointF[]]@(
            [System.Drawing.PointF]::new($tip[0],$tip[1]),
            [System.Drawing.PointF]::new($baseX+7*[Math]::Sin($angle),$baseY-7*[Math]::Cos($angle)),
            [System.Drawing.PointF]::new($baseX-7*[Math]::Sin($angle),$baseY+7*[Math]::Cos($angle))
        )
        $brush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($Color))
        $graphics.FillPolygon($brush,$arrowPoints)
        $arrowString = ($arrowPoints | ForEach-Object {"$($_.X),$($_.Y)"}) -join ' '
        $svg.Add("<polygon points='$arrowString' fill='$Color'/>")
        $brush.Dispose()
    }
    $dashStyle = if ($Dashed) {'dashed=1;dashPattern=5 3;'} else {''}
    $endStyle = if ($Arrow) {'block'} else {'none'}
    $attachments = @{
        'flex-adc' = @('flex','esp32',1,0.5,0,0.25)
        'imu-i2c' = @('imu','esp32',1,0.5,0,0.775)
        'ble' = @('esp32','phone',1,0.5,0,0.5294118)
        'cloud' = @('phone','firebase',1,0.5294118,0,0.5)
        'imu-replacement' = @('new-imu','imu',0.5,0,0.5,1)
        'piezo-drive' = @('esp32','piezo',0.5,1,0.5,0)
        'future-cue-logic' = @('phone','correction',0.5,1,0.5,0)
        'future-commands' = @('correction','esp32',0,0.5,0.8571429,1)
    }
    $attachmentAttributes = ''
    $attachmentStyle = ''
    if ($attachments.ContainsKey($Id)) {
        $a = $attachments[$Id]
        $attachmentAttributes = " source='$($a[0])' target='$($a[1])'"
        $attachmentStyle = "exitX=$($a[2]);exitY=$($a[3]);entryX=$($a[4]);entryY=$($a[5]);"
    }
    $mxPoints = [System.Collections.Generic.List[string]]::new()
    for ($i=1; $i -lt $Points.Count-1; $i++) { $mxPoints.Add("<mxPoint x='$($Points[$i][0])' y='$($Points[$i][1])'/>") }
    $cells.Add("<mxCell id='$Id' value='' style='edgeStyle=none;rounded=0;html=0;endArrow=$endStyle;endFill=1;strokeColor=$Color;strokeWidth=3;$dashStyle$attachmentStyle' edge='1' parent='1'$attachmentAttributes><mxGeometry relative='1' as='geometry'><mxPoint x='$($Points[0][0])' y='$($Points[0][1])' as='sourcePoint'/><mxPoint x='$($Points[-1][0])' y='$($Points[-1][1])' as='targetPoint'/><Array as='points'>$($mxPoints -join '')</Array></mxGeometry></mxCell>")
    $pen.Dispose()
}

# Native boxes and orthogonal connectors use the familiar diagrams.net palette.
Add-Text -Id title -Text 'Helping Hand system architecture' -X 45 -Y 24 -W 1710 -H 62 -Size 44 -Bold $true -Align Left
Add-Text -Id subtitle -Text 'Implemented paths and planned hardware integration' -X 45 -Y 88 -W 1710 -H 42 -Size 30 -Align Left
Add-Line -Id legend-solid -Points @(@(50,161),@(135,161)) -Arrow $false
Add-Text -Id legend-solid-label -Text 'Implemented' -X 150 -Y 140 -W 260 -H 42 -Size 28 -Align Left
Add-Line -Id legend-planned -Points @(@(510,161),@(595,161)) -Dashed $true -Arrow $false -Color '#8c7622'
Add-Text -Id legend-planned-label -Text 'Planned / not yet integrated' -X 610 -Y 140 -W 850 -H 42 -Size 28 -Align Left

Add-Box -Id current-frame -X 35 -Y 205 -W 1730 -H 465 -Fill '#fafafa' -Stroke '#b8b8b8'
Add-Text -Id current-label -Text 'IMPLEMENTED SYSTEM' -X 55 -Y 213 -W 800 -H 44 -Size 27 -Bold $true -Align Left
Add-Box -Id planned-frame -X 35 -Y 735 -W 1730 -H 430 -Fill '#fffdf7' -Stroke '#b8a767' -Dashed $true

Add-Line -Id flex-adc -Points @(@(370,345),@(435,345),@(435,400),@(520,400))
Add-Line -Id imu-i2c -Points @(@(370,535),@(435,535),@(435,505),@(520,505))
Add-Line -Id ble -Points @(@(800,450),@(980,450))
Add-Line -Id cloud -Points @(@(1340,450),@(1490,450))
Add-Line -Id imu-replacement -Points @(@(220,860),@(220,595)) -Dashed $true -Color '#8c7622'
Add-Line -Id piezo-drive -Points @(@(660,550),@(660,860)) -Dashed $true -Color '#8c7622'
Add-Line -Id future-cue-logic -Points @(@(1160,610),@(1160,860)) -Dashed $true -Color '#8c7622'
Add-Line -Id future-commands -Points @(@(980,940),@(875,940),@(875,630),@(760,630),@(760,550)) -Dashed $true -Color '#8c7622'
Add-Box -Id planned-label-backing -X 50 -Y 744 -W 440 -H 47 -Fill '#fffdf7' -Stroke '#fffdf7'
Add-Text -Id planned-label -Text 'PLANNED INTEGRATION' -X 55 -Y 745 -W 430 -H 44 -Size 27 -Bold $true -Align Left

Add-Box -Id flex -X 70 -Y 285 -W 300 -H 120 -Lines @('5 flex sensors','Finger-bend values')
Add-Box -Id imu -X 70 -Y 475 -W 300 -H 120 -Lines @('6-axis IMU','Acceleration + gyro')
Add-Box -Id esp32 -X 520 -Y 350 -W 280 -H 200 -Lines @('ESP32-S3','Read sensors','Static MLP','34 classes')
Add-Box -Id phone -X 980 -Y 270 -W 360 -H 340 -Fill '#d5e8d4' -Stroke '#82b366' -Lines @('Flutter Android app','Practice + feedback','Word TCN','Hello / Please / Yes','Local progress (JSON)','Recording / export')
Add-Box -Id firebase -X 1490 -Y 375 -W 240 -H 150 -Lines @('Firebase','Authentication','Firestore')

Add-Box -Id new-imu -X 70 -Y 860 -W 300 -H 160 -Fill '#fff2cc' -Stroke '#b5a04c' -Dashed $true -Lines @('9-axis IMU','ICM-20948','Calibration pending')
Add-Box -Id piezo -X 500 -Y 860 -W 320 -H 160 -Fill '#fff2cc' -Stroke '#b5a04c' -Dashed $true -Lines @('10 piezo elements','5 finger + 5 hand','Drivers / cues','pending')
Add-Box -Id correction -X 980 -Y 860 -W 360 -H 160 -Fill '#fff2cc' -Stroke '#b5a04c' -Dashed $true -Lines @('Correction logic','Map errors to cues','Needs development')
Add-Box -Id pcb -X 1490 -Y 860 -W 240 -H 160 -Fill '#fff2cc' -Stroke '#b5a04c' -Dashed $true -Lines @('Custom PCB','Replaces','perfboard','Not fabricated')

Add-Text -Id adc-label -Text 'ADC' -X 378 -Y 299 -W 125 -H 39 -Size 28
Add-Text -Id i2c-label -Text 'I2C' -X 378 -Y 553 -W 125 -H 39 -Size 28
Add-Text -Id ble-label -Text 'BLE / GATT' -X 800 -Y 397 -W 180 -H 40 -Size 28
Add-Text -Id https-label -Text 'HTTPS' -X 1340 -Y 397 -W 150 -H 40 -Size 28
Add-Text -Id network-label-1 -Text 'Wi-Fi /' -X 1340 -Y 469 -W 150 -H 35 -Size 26
Add-Text -Id network-label-2 -Text 'cellular' -X 1340 -Y 501 -W 150 -H 35 -Size 26
Add-Text -Id replacement-label -Text 'Replaces' -X 236 -Y 675 -W 185 -H 42 -Size 27 -Align Left
Add-Text -Id gpio-label -Text 'GPIO / driver' -X 676 -Y 686 -W 230 -H 42 -Size 26 -Align Left
Add-Text -Id commands-label -Text 'Future BLE commands' -X 738 -Y 637 -W 310 -H 37 -Size 25
Add-Text -Id logic-label -Text 'Planned cue logic' -X 1176 -Y 686 -W 310 -H 42 -Size 26 -Align Left
Add-Text -Id pcb-note -Text 'The custom PCB will replace the perfboard wiring and mounting.' -X 65 -Y 1078 -W 1670 -H 43 -Size 28 -Align Left
Add-Text -Id model-note -Text 'Current word inputs: flex + accelerometer / gyroscope. Magnetic features would require model updates.' -X 45 -Y 1183 -W 1710 -H 42 -Size 27 -Align Left
Add-Text -Id correction-note -Text 'A word prediction alone does not specify which finger needs correction.' -X 45 -Y 1223 -W 1710 -H 38 -Size 27 -Align Left

$svg.Add('</svg>')
$svgPath = Join-Path $outputDir 'helping-hand-architecture.svg'
$pngPath = Join-Path $outputDir 'helping-hand-architecture.png'
$drawioPath = Join-Path $outputDir 'helping-hand-architecture.drawio'
[System.IO.File]::WriteAllText($svgPath,($svg -join "`n"),[System.Text.UTF8Encoding]::new($false))
$drawioXml = '<mxfile host="app.diagrams.net" agent="Helping Hand report figure"><diagram name="Helping Hand architecture" id="r3-architecture"><mxGraphModel dx="1800" dy="1280" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="1800" pageHeight="1280" math="0" shadow="0"><root>' + ($cells -join "`n") + '</root></mxGraphModel></diagram></mxfile>'
[System.IO.File]::WriteAllText($drawioPath,$drawioXml,[System.Text.UTF8Encoding]::new($false))
[xml]$validatedSvg = [System.IO.File]::ReadAllText($svgPath)
[xml]$validatedDrawio = [System.IO.File]::ReadAllText($drawioPath)
$bitmap.Save($pngPath,[System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose(); $bitmap.Dispose()
Write-Output "Saved PNG, SVG, and draw.io XML to $outputDir"
