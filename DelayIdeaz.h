#ifndef __DELAYIDEAZ__
#define __DELAYIDEAZ__

#include "IPlug_include_in_plug_hdr.h"
#include <list>

class DelayIdeaz : public IPlug
{
public:
  DelayIdeaz(IPlugInstanceInfo instanceInfo);
  ~DelayIdeaz();

  void Reset();
  void OnParamChange(int paramIdx);
  void ProcessDoubleReplacing(double** inputs, double** outputs, int nFrames);

private:
  double mThreshold;
  void CreatePresets();
  std::list<double*> DelayArray;
  std::list<double> AudioArray;

};

#endif
