#include "DelayIdeaz.h"
#include "IPlug_include_in_plug_src.h"
#include "IControl.h"
#include "resource.h"
#include <list>

const int kNumPrograms = 5;

enum EParams
{
  ktime = 0,
  kFeedback=1,
  kNumParams
};

enum ELayout
{
  kWidth = GUI_WIDTH,
  kHeight = GUI_HEIGHT,

  ktimeX = 79,
  ktimeY = 62,
  kKnobFrames = 128,

  kFeedbackX = 279,
  kFeedbackY = 62,
  kKnobFramesFB = 128
};

void DelayIdeaz::CreatePresets() {
	MakePreset("100ms", 100.0);
	MakePreset("slightly distorted", 80.0);
	MakePreset("woooo", 40.0);
	MakePreset("waaaa", 20.0);
	MakePreset("buzzz!!!", 0.01);
}

DelayIdeaz::DelayIdeaz(IPlugInstanceInfo instanceInfo)
  :	IPLUG_CTOR(kNumParams, kNumPrograms, instanceInfo), mtime(1.), mFeedback(1.)
{
  TRACE;

  //arguments are: name, defaultVal, minVal, maxVal, step, label
  GetParam(ktime)->InitDouble("Delay Time", 1, 1, 2000.0, 45, "msec");
  GetParam(ktime)->SetShape(2.);

  GetParam(kFeedback)->InitDouble("Feedback", 50, 1, 99.0, 1, "%");
  GetParam(kFeedback)->SetShape(2.);

  IGraphics* pGraphics = MakeGraphics(this, kWidth, kHeight);
  //pGraphics->AttachPanelBackground(&COLOR_GRAY); //old one-color background
  pGraphics->AttachBackground(BACKGROUND_ID, BACKGROUND_FN);

  IBitmap knob = pGraphics->LoadIBitmap(KNOB_ID, KNOB_FN, kKnobFrames);
  IBitmap knobFB = pGraphics->LoadIBitmap(KNOB_ID, KNOB_FN, kKnobFramesFB);

  pGraphics->AttachControl(new IKnobMultiControl(this, ktimeX, ktimeY, ktime, &knob));
  pGraphics->AttachControl(new IKnobMultiControl(this, kFeedbackX, kFeedbackY, kFeedback, &knob));

  AttachGraphics(pGraphics);

  //MakePreset("preset 1", ... );
  //MakeDefaultPreset((char *) "-", kNumPrograms);
  //implementing presets below; old code above...
  CreatePresets();


  
}

DelayIdeaz::~DelayIdeaz() {}

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
		AudioArray.push_back(*output / mFeedback);
		//.5 sub'd for mFeedback
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
    case ktime:
      mtime = GetParam(ktime)->Value();
	  AudioArray.clear();
	  for (int i = 0; i < ((int)(44.1*mtime)); i++) {
		  AudioArray.push_back(0);
	  }
      break;

	case kFeedback:
		mFeedback = (100 / ((int)(GetParam(kFeedback)->Value())));
		AudioArray.clear();

		for (int i = 0; i < ((int)(44.1*mtime)); i++) {
			AudioArray.push_back(0);
		}
		break;

    default:
      break;
  }
}
