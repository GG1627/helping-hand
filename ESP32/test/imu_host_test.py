"""Host-only IMU register/units regression checks; run with Python 3 and g++.

Uses a simulated Wire bus, not physical hardware.
"""
from pathlib import Path
import tempfile,subprocess
root=Path(__file__).resolve().parents[2];d=Path(tempfile.mkdtemp(prefix='hh-imu-',dir='/tmp'))
(d/'Arduino.h').write_text('''#pragma once
#include <cstdint>
#include <cstddef>
constexpr int SDA=3,SCL=4,A0=18,A1=17,A2=16,A3=15,A4=14,A5=8,SCK=36,MISO=37,MOSI=35;
constexpr int OUTPUT=1,HIGH=1;
extern uint32_t clockMs;
inline uint32_t millis(){return clockMs;}
inline void delay(uint32_t n){clockMs+=n;}
inline void pinMode(int,int){} inline void digitalWrite(int,int){}
struct SerialMock {template<class... T> void printf(const char*,T...){} void println(const char*){}};
extern SerialMock Serial;
''')
(d/'Wire.h').write_text('''#pragma once
#include <cstdint>
#include <vector>
#include <map>
#include <tuple>
struct WireMock {
 int kind=0,addr=0x68,bank=0,reg=0,target=0,pos=0; bool fail=false,overflow=false,ready=true;
 std::vector<uint8_t> tx,rx;
 std::map<std::tuple<int,int,int>,int> regs;
 bool begin(int,int){return true;} void setClock(int){}
 void beginTransmission(int a){target=a;tx.clear();}
 void write(uint8_t b){tx.push_back(b);}
 int endTransmission(bool){
  if(fail || (target!=addr&&target!=0x0c) || (target==0x0c&&kind!=1)) return 4;
  reg=tx[0];
  if(tx.size()==2){
   if(target==addr&&kind==1&&reg==0x7f) bank=tx[1]>>4;
   else regs[{target,bank,reg}]=tx[1];
  }
  return 0;
 }
 int requestFrom(int a,int n,int){
  rx.clear();pos=0;if(fail) return 0;
  for(int i=0;i<n;++i){int r=reg+i,v=0;
   if(a==addr){
    if(kind==1&&bank==0&&r==0) v=0xea;
    else if(kind==2&&r==0x75) v=0x68;
    else if(kind==3&&r==0x75) v=0xff;
    else if((kind==1&&bank==0&&reg==0x2d)||(kind==2&&reg==0x3b)){
     int g=kind==1?6:8;
     if(i==0)v=0x40;
     if(i==2)v=0xc0;
     if(i==g)v=0x00;
     if(i==g+1)v=131;
     if(i==g+2)v=0xff;
     if(i==g+3)v=0x7d;
    }else {auto it=regs.find({a,bank,r});if(it!=regs.end())v=it->second;}
   }else if(a==0xc){
    if(reg==0&&i==0)v=0x48;else if(reg==0&&i==1)v=0x09;
    else if(reg==0x10)v=ready?1:0;
    else if(reg==0x11){if(i==0)v=10;if(i==2)v=0xf6;if(i==3)v=0xff;if(i==7)v=overflow?8:0;}
   }
   rx.push_back(v);
  }return n;
 }
 int read(){return rx[pos++];}
};
extern WireMock Wire;
''')
(d/'test.cpp').write_text('''#include "Arduino.h"
#include "Wire.h"
#include "imu_sensor.h"
#include <cassert>
#include <cmath>
#include <cstdio>
uint32_t clockMs=0; SerialMock Serial; WireMock Wire;
void near(float a,float b){assert(std::fabs(a-b)<0.001f);}
int main(){
 Wire.kind=1;setupImu();assert(getImuWhoAmI()==0xea);
 assert(Wire.regs[std::make_tuple(0x68,2,0x14)]==0x19);
 assert(Wire.regs[std::make_tuple(0x68,2,0x01)]==0x19);
 ImuSample s{};assert(readImuSample(s));near(s.axG,1);near(s.ayG,-1);near(s.gxDps,1);near(s.gyDps,-1);
 MagneticSample m{};assert(readMagneticSample(m));near(m.mxUt,1.5);near(m.myUt,-1.5);
 Wire.ready=false;assert(!readMagneticSample(m));Wire.ready=true;
 Wire.overflow=true;assert(!readMagneticSample(m));Wire.overflow=false;
 Wire.fail=true;assert(!readImuSample(s));assert(!readMagneticSample(m));
 Wire.fail=false;clockMs+=2000;updateImu();assert(readImuSample(s));
 Wire.kind=2;setupImu();assert(getImuWhoAmI()==0x68);assert(readImuSample(s));
 near(s.axG,1);near(s.ayG,-1);near(s.gxDps,1);near(s.gyDps,-1);assert(!readMagneticSample(m));
 Wire.kind=1;Wire.addr=0x69;setupImu();assert(getImuWhoAmI()==0xea);assert(readImuSample(s));
 Wire.kind=3;setupImu();assert(!readImuSample(s));assert(!readMagneticSample(m));
 puts("PASS: ICM bank/ranges, signed motion/magnetic units, not-ready/overflow rejection, disconnect/retry, legacy fallback, alternate address, unknown ID rejection");
}
''')
subprocess.run(['g++','-std=c++11','-Wall','-Wextra','-I'+str(d),'-I'+str(root/'ESP32/include'),str(root/'ESP32/src/imu_sensor.cpp'),str(d/'test.cpp'),'-o',str(d/'test')],check=True)
subprocess.run([str(d/'test')],check=True)
