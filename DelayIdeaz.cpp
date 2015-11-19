#include "DelayIdeaz.h"
#include "IPlug_include_in_plug_src.h"
#include "IControl.h"
#include "resource.h"
#include <list>

const int kNumPrograms = 5;

enum EParams
{
  kThreshold = 0,
  kNumParams
};

enum ELayout
{
  kWidth = GUI_WIDTH,
  kHeight = GUI_HEIGHT,

  kThresholdX = 79,
  kThresholdY = 62,
  kKnobFrames = 128
};

void DelayIdeaz::CreatePresets() {
	MakePreset("clean", 100.0);
	MakePreset("slightly distorted", 80.0);
	MakePreset("woooo", 40.0);
	MakePreset("waaaa", 20.0);
	MakePreset("buzzz!!!", 0.01);
}

DelayIdeaz::DelayIdeaz(IPlugInstanceInfo instanceInfo)
  :	IPLUG_CTOR(kNumParams, kNumPrograms, instanceInfo), mThreshold(1.)
{
  TRACE;

  //arguments are: name, defaultVal, minVal, maxVal, step, label
  GetParam(kThreshold)->InitDouble("Delay Time", 1, 1, 2000.0, 50, "msec");
  GetParam(kThreshold)->SetShape(2.);


  IGraphics* pGraphics = MakeGraphics(this, kWidth, kHeight);
  //pGraphics->AttachPanelBackground(&COLOR_GRAY); //old one-color background
  pGraphics->AttachBackground(BACKGROUND_ID, BACKGROUND_FN);

  IBitmap knob = pGraphics->LoadIBitmap(KNOB_ID, KNOB_FN, kKnobFrames);

  pGraphics->AttachControl(new IKnobMultiControl(this, kThresholdX, kThresholdY, kThreshold, &knob));

  AttachGraphics(pGraphics);

  //MakePreset("preset 1", ... );
  //MakeDefaultPreset((char *) "-", kNumPrograms);
  //implementing presets below; old code above...
  CreatePresets();


  
}

DelayIdeaz::~DelayIdeaz() {}

//to-do - add feedback and delay time knobs

void DelayIdeaz::ProcessDoubleReplacing(double** inputs, double** outputs, int nFrames)
{
  // Mutex is already locked for us.

	int const channelCount = 2;

  for (int i = 0; i < channelCount; i++) {
    double* input = inputs[i];
	double* output = outputs[i];

	
	for (int s = 0; s < nFrames; ++s, ++input, ++output) {
		*output = (*input + AudioArray.front());
		AudioArray.pop_front();
		//feedback = 
		AudioArray.push_back(*output / 2);
	}
  }
}

void DelayIdeaz::Reset()
{
  TRACE;	
  IMutexLock lock(this);
}

void DelayIdeaz::OnParamChange(int paramIdx)
{
  IMutexLock lock(this);

  switch (paramIdx)
  {
    case kThreshold:
      mThreshold = GetParam(kThreshold)->Value();
	  
	  AudioArray.clear();

	  for (int i = 0; i < ((int)(44.1*mThreshold)); i++) {
		  AudioArray.push_back(0);
	  }
      break;

    default:
      break;
  }
}
