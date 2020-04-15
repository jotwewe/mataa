/**
 * DISCLAIMER:
 * This file is part of MATAA.
 * 
 * MATAA is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * MATAA is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with MATAA; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * Based on TestDevicesPA19.c and TestTonePA19.c, Copyright (C) Matthias S. Brennwald.
 * Copyright (C) 2020 Jens W. Wulf.
 */ 
 
#include <octave/oct.h>
#include <octave/ov-struct.h>
#include <octave/Cell.h>
#include <octave/ov-cell.h>

#include "portaudio.h"

// todo: testen
#undef REALTIME_ALSA_THREAD

#ifdef REALTIME_ALSA_THREAD
# include "pa_linux_alsa.h"
#endif

#define PA_SAMPLE_TYPE  paFloat32
typedef float           SAMPLE;

typedef struct
{
  unsigned long numFrames;
  unsigned long processedFrames;
  unsigned int  numInputDeviceChannels;
  unsigned int  numOutputDeviceChannels;
  float         samplingRate;
  SAMPLE        *inputSamples;
  SAMPLE        *outputSamples;
}
paTestData, *paTestDataPtr;

/* This routine will be called by the PortAudio engine when audio is needed.
 ** It may be called at interrupt level on some machines so don't do anything
 ** that could mess up the system like calling malloc() or free().
 */
static int RecordAndPlayCallback(const void *inputBuffer,
                                 void *outputBuffer,
                                 unsigned long framesPerBuffer,
                                 const PaStreamCallbackTimeInfo* outTime,
                                 PaStreamCallbackFlags statusFlags,
                                 void *userData )
{
  unsigned long iF,iFmax,remainingFrames,iC;
  paTestData* data;
  int finished;
  
  /* Cast data passed through stream to our structure. */
  data = (paTestDataPtr)userData;
  
  /* Handle sound output buffer */
  SAMPLE *out = (SAMPLE*)outputBuffer;
  remainingFrames = data->numFrames - data->processedFrames;
  if (remainingFrames > framesPerBuffer)
  {
    iFmax=framesPerBuffer;
    finished=0;
  }
  else
  { /* last buffer... */
    iFmax=remainingFrames;
    finished=1;
  }
  
  for( iF=0; iF<iFmax; iF++ )
  {
    for( iC=0; iC < data->numOutputDeviceChannels; iC++ ) {
      *out++ = data->outputSamples[(iF+data->processedFrames)*data->numOutputDeviceChannels+iC];
    }
  }
  
  /* Handle sound input buffer */
  SAMPLE *in = (SAMPLE*)inputBuffer;
  for( iF=0; iF<iFmax; iF++ )
  {
    for( iC=0; iC<data->numInputDeviceChannels; iC++ ) 
      data->inputSamples[(iF+data->processedFrames)*data->numInputDeviceChannels+iC]=*in++;
  }
  
  /* Prepare for next callback-cycle: */    
  data->processedFrames += iFmax;
  
  return finished;
}

Matrix TestTonePA19_main(double        samplingRate,
                         Matrix        testsignal,
                         int           outputDevice,
                         int           inputDevice,
                         unsigned long framesPerBuffer,
                         double        latency)
{
  PaError err;
  try
  {
    PaStream      *stream;
    paTestData    data;
    
    // initialize PortAudio:
    err = Pa_Initialize();
    if (err != paNoError)
      throw std::runtime_error("Error: Pa_Initialize()");
    
    // get audio devices info:
    if (outputDevice < 0)
      outputDevice = Pa_GetDefaultOutputDevice();
    if (inputDevice < 0)
      inputDevice  = Pa_GetDefaultInputDevice();    
    
    if (inputDevice < 0)
    {      
      err = inputDevice;
      throw std::runtime_error("ERROR: Pa_GetDefaultInputDevice returned negative value");
    }
    const   PaDeviceInfo *inputInfo;
    inputInfo = Pa_GetDeviceInfo( inputDevice );
    
    if (outputDevice < 0)
    {
      err = outputDevice;
      throw std::runtime_error("ERROR: Pa_GetDefaultOutputDevice returned negative value");
    }
    const   PaDeviceInfo *outputInfo;
    outputInfo = Pa_GetDeviceInfo( outputDevice );
    
    // printf( "% Output %i, input %i\n", outputDevice, inputDevice );
    
    // get number of data channels in input file:
    int numChanTestSignal = testsignal.columns();
    printf("%% Number of data channels in input file = %d\n", numChanTestSignal);
    
    if ( numChanTestSignal > outputInfo->maxOutputChannels) 
    {
      throw std::runtime_error("ERROR: the input file has more channels than supported by the sound output device");
    }
    
    // Prepare data:
    data.numOutputDeviceChannels = numChanTestSignal;
    if (data.numOutputDeviceChannels < 2)
      data.numOutputDeviceChannels = 2;

    data.numInputDeviceChannels  = inputInfo->maxInputChannels;
    if (data.numInputDeviceChannels > 2)
      data.numInputDeviceChannels = 2;

    data.processedFrames = 0;
    data.samplingRate    = samplingRate;    
    data.numFrames       = testsignal.rows();

    octave_stdout << "Using " << data.numOutputDeviceChannels << " output channels.\n";
    octave_stdout << "Using " << data.numInputDeviceChannels << " input channels.\n";
    
    // allocate memory for output data:
    unsigned long numBytes = data.numFrames * data.numOutputDeviceChannels * sizeof(SAMPLE);
    data.outputSamples= (SAMPLE *) malloc( numBytes );
    if( data.outputSamples == NULL )
    {
      throw std::runtime_error("ERROR: could not allocate output frames buffer.");
    }
    
    // move the testSignal to data.outputSamples:
    {
      unsigned int iChannelTest;  
      for (unsigned int iChannelOut = 0; iChannelOut < data.numOutputDeviceChannels; iChannelOut++)
      {
        if (iChannelOut < numChanTestSignal) 
        {
          iChannelTest = iChannelOut;
        }
        else
        {
          iChannelTest = numChanTestSignal-1;
        }
        for (unsigned long iFrame = 0; iFrame < data.numFrames; iFrame++ ) 
        {
          data.outputSamples[data.numOutputDeviceChannels*iFrame+iChannelOut] = testsignal(iFrame, iChannelTest);
        }
      }
    }
    
    numBytes = data.numFrames * data.numInputDeviceChannels * sizeof(SAMPLE);
    data.inputSamples= (SAMPLE *) malloc( numBytes );
    if( data.inputSamples == NULL )
    {
      printf("Could not allocate output frames buffer");
      exit(1);
    }
    
    for (unsigned long iFrame=0; iFrame<data.numFrames; iFrame++) // initialize input frames:
    {
      for (unsigned int iChannel=0; iChannel < data.numInputDeviceChannels; iChannel++)
      {
        data.inputSamples[iFrame*data.numInputDeviceChannels+iChannel] = 0;
      }
    }
    
    // Record and play audio data:
        
    PaStreamParameters outputParameters;
    PaStreamParameters inputParameters;
    
    bzero( &inputParameters, sizeof( inputParameters ) ); //not necessary if you are filling in all the fields
    inputParameters.channelCount              = data.numInputDeviceChannels;  // number of input channels
    inputParameters.device                    = inputDevice;
    inputParameters.hostApiSpecificStreamInfo = NULL;
    inputParameters.sampleFormat              = paFloat32;
    inputParameters.suggestedLatency          = Pa_GetDeviceInfo(inputParameters.device)->defaultHighInputLatency ;
    inputParameters.hostApiSpecificStreamInfo = NULL; //See you specific host's API docs for info on using this field
    
    bzero( &outputParameters, sizeof( outputParameters ) ); //not necessary if you are filling in all the fields
    outputParameters.channelCount              = data.numOutputDeviceChannels; // number of output channels
    outputParameters.device                    = outputDevice;
    outputParameters.hostApiSpecificStreamInfo = NULL;
    outputParameters.sampleFormat              = paFloat32;
    outputParameters.suggestedLatency          = Pa_GetDeviceInfo(outputParameters.device)->defaultHighOutputLatency ;
    outputParameters.hostApiSpecificStreamInfo = NULL; //See you specific host's API docs for info on using this field
        
    // audacity benutzt defaultHighInputLatency und defaultLowOutputLatency oder
    // DEFAULT_LATENCY_DURATION 100.0 -- was man aber einstellen kann (bei mir noch 
    // auf dem Defaultwert).
    if (latency > 0)
    {
      inputParameters.suggestedLatency  = latency;
      outputParameters.suggestedLatency = inputParameters.suggestedLatency;
    }
    
    // Kommentar aus dem audacity-Code:    
    //   (Linux, bug 1885) After scanning devices it takes a little time for the
    //   ALSA device to be available, so allow retries.
    //   On my test machine, no more than 3 attempts are required.
    for (int nTries=4; nTries >= 0; nTries--)
    {
      err = Pa_OpenStream(&stream,
                          &inputParameters,
                          &outputParameters,
                          data.samplingRate,     // sampling rate
                          framesPerBuffer,
                          paNoFlag,              // flags that can be used to define dither, clip settings and more
                          RecordAndPlayCallback, // the callback function
                          &data );               // pointer to the audio data
      if (err == paNoError)
      {
        break;
      }
      else 
      {
        if (nTries == 0)
          throw std::runtime_error( "ERROR: Pa_OpenDefaultStream returned...");
        Pa_Sleep(1000);
      }
    }

#ifdef REALTIME_ALSA_THREAD
    PaAlsa_EnableRealtimeScheduling(stream, 1);
#endif
    
    err = Pa_StartStream( stream );
    if( err != paNoError ) 
    {
      throw std::runtime_error( "ERROR: Pa_StartStream returned...");
    }
    
    while( Pa_IsStreamActive( stream ) )
    {
      Pa_Sleep(1); // sleep while audio I/O
    }
    err = Pa_CloseStream( stream );
    if( err != paNoError ) 
    {
      throw std::runtime_error( "ERROR: Pa_CloseStream returned...");
    }
    
    Pa_Terminate();
    
    Matrix recordedSignal(data.numFrames, 1+data.numInputDeviceChannels);
    for(unsigned long iFrame=0; iFrame<data.numFrames; iFrame++)
    {
      recordedSignal(iFrame,0) = (float)iFrame / data.samplingRate;
      for(unsigned int iChannel = 0; iChannel < data.numInputDeviceChannels; iChannel++)
      {
        recordedSignal(iFrame,1+iChannel) = data.inputSamples[iFrame*data.numInputDeviceChannels+iChannel];
      }
    }
    
    // clean up:
    free(data.inputSamples);
    free(data.outputSamples);
    
    // exit:
    return recordedSignal;
  }
  catch (std::runtime_error &e)
  {
    octave_stdout << "An error occured while using the portaudio stream:\n";
    octave_stdout << e.what() << "\n";
    octave_stdout << "Error number:  " << err << "\n";
    octave_stdout << "Error message: " << Pa_GetErrorText( err ) << "\n";
    octave_stdout << "Last error from host API: " << Pa_GetLastHostErrorInfo()->errorText << "\n";

    Pa_Terminate();
    Matrix ret_err(0,0);
    return ret_err;  
  }
}

Matrix* PrintSupportedStandardSampleRates(const PaStreamParameters *inputParameters,
                                          const PaStreamParameters *outputParameters,
                                          int nList)
{
  static double standardSampleRates[] = {
    8000.0, 9600.0, 11025.0, 12000.0, 16000.0, 22050.0, 24000.0, 32000.0,
    44100.0, 48000.0, 88200.0, 96000.0, 192000.0, -1 /* negative terminated  list */
  };
  int     i, printCount;
  PaError err;
  Matrix* vSamplerates = new Matrix(1, sizeof(standardSampleRates)/sizeof(double)-1);
  
  if (nList)
    octave_stdout << "\n      ";
  printCount = 0;
  for( i=0; standardSampleRates[i] > 0; i++ )
  {
    err = Pa_IsFormatSupported( inputParameters, outputParameters, standardSampleRates[i] );
    if (err == paFormatIsSupported)
    {
      if (nList)
        octave_stdout << standardSampleRates[i] << " ";
      (*vSamplerates)(printCount,0) = standardSampleRates[i];
      printCount++;
    }
  }
  if (nList)
  {
    if( !printCount )
      octave_stdout << "None\n";
    else
      octave_stdout << "\n";
  }
  return vSamplerates;
}

void copy_info(const PaDeviceInfo* deviceInfo, PaStreamParameters* parameters,
               Matrix* samplerates_hd, Matrix* samplerates_fd,
               bool bFullDuplex,
               octave_map& info)
{
  info.assign("name", octave_value(deviceInfo->name));
  info.assign("API", octave_value(Pa_GetHostApiInfo( deviceInfo->hostApi )->name));
  if (bFullDuplex)
    info.assign("sampleRates", octave_value(*samplerates_fd));
  else
   info.assign("sampleRates", octave_value(*samplerates_hd));
  info.assign("channels", octave_value(parameters->channelCount));  
}

octave_map TestDevicesPA19(int nList)
{
  const   PaDeviceInfo *deviceInfo;
  PaStreamParameters inputParameters, outputParameters;
  PaError err;
  
  octave_map default_inout;
  
  try
  {
    Pa_Initialize();

    if (nList)
    {
      octave_stdout << "PortAudio version number = " << Pa_GetVersion() << "\n";
      octave_stdout << "PortAudio version text   = " << Pa_GetVersionText() << "\n";
    }
        
    int numDevices = Pa_GetDeviceCount();
    if( numDevices < 0 )
    {
      err = numDevices;
      throw std::runtime_error("ERROR: Pa_GetDeviceCount returned...");
    }

    int default_in  = Pa_GetDefaultInputDevice();
    int default_out = Pa_GetDefaultOutputDevice();
    if (nList)
    {
      octave_stdout << "Pa_GetDefaultInputDevice()  = " << default_in  << "\n";
      octave_stdout << "Pa_GetDefaultOutputDevice() = " << default_out << "\n";
    }
    
    Matrix* samplerates_hd;
    Matrix* samplerates_fd;

    octave_map info_in;
    octave_map info_out;
    
    for(int i=0; i<numDevices; i++ )
    {
      deviceInfo = Pa_GetDeviceInfo( i );
      
      if (nList)
      {
        octave_stdout << "--- " << i << ", device = " << deviceInfo->name << " ------------------------------------\n";
        octave_stdout << "  Host API = " << Pa_GetHostApiInfo( deviceInfo->hostApi )->name << "\n";
      }
      
      inputParameters.device = i;
      inputParameters.channelCount = deviceInfo->maxInputChannels;
      inputParameters.sampleFormat = paInt16;
      inputParameters.suggestedLatency = 0; /* ignored by Pa_IsFormatSupported() */
      inputParameters.hostApiSpecificStreamInfo = NULL;
      
      outputParameters.device = i;
      outputParameters.channelCount = deviceInfo->maxOutputChannels;
      outputParameters.sampleFormat = paInt16;
      outputParameters.suggestedLatency = 0; /* ignored by Pa_IsFormatSupported() */
      outputParameters.hostApiSpecificStreamInfo = NULL;
        
      if (i == default_in || nList)
      {
        if (nList)
          octave_stdout << "  Max input channels = " << deviceInfo->maxInputChannels << "\n";
        
        samplerates_hd = (Matrix*)0;
        samplerates_fd = (Matrix*)0;
        
        if( inputParameters.channelCount > 0 )
        {
          if (nList)
            octave_stdout << "    Supported standard sample rates (input, half-duplex, 16 bit, " << inputParameters.channelCount << " channels) = ";
          samplerates_hd = PrintSupportedStandardSampleRates(&inputParameters, NULL, nList);
        }
        
        if( inputParameters.channelCount > 0 && outputParameters.channelCount > 0 )
        {
          if (nList)
            octave_stdout << "    Supported standard sample rates (input, full-duplex, 16 bit, " << inputParameters.channelCount << " channels) = ";
          samplerates_fd = PrintSupportedStandardSampleRates(&inputParameters, &outputParameters, nList);
        }
        
        if (i == default_in)
        {
          copy_info(deviceInfo, &inputParameters, samplerates_hd, samplerates_fd, default_in==default_out, info_in);
        }

        if (samplerates_fd != (Matrix*)0)
          delete samplerates_fd;
        if (samplerates_hd != (Matrix*)0)
          delete samplerates_hd;
      }
      
      if (i == default_out || nList)
      {
        if (nList)
          octave_stdout << "  Max output channels = " << deviceInfo->maxOutputChannels << "\n";
        
        samplerates_hd = (Matrix*)0;
        samplerates_fd = (Matrix*)0;
        
        if( outputParameters.channelCount > 0 )
        {
          if (nList)
            octave_stdout << "    Supported standard sample rates (output, half-duplex, 16 bit, " << outputParameters.channelCount << " channels) = ";
          samplerates_hd = PrintSupportedStandardSampleRates(NULL, &outputParameters, nList);
        }
        
        if( inputParameters.channelCount > 0 && outputParameters.channelCount > 0 )
        {
          if (nList)
            octave_stdout << "    Supported standard sample rates (output, full-duplex, 16 bit, " << outputParameters.channelCount << " channels) = ";
          samplerates_fd = PrintSupportedStandardSampleRates(&inputParameters, &outputParameters, nList);
        }
        
        if (i == default_out)
        {
          copy_info(deviceInfo, &outputParameters, samplerates_hd, samplerates_fd, default_in==default_out, info_out);
        }
        
        if (samplerates_fd != (Matrix*)0)
          delete samplerates_fd;
        if (samplerates_hd != (Matrix*)0)
          delete samplerates_hd;
      }
    }

    default_inout.assign("input",  octave_value(info_in));
    default_inout.assign("output", octave_value(info_out));
    
    Pa_Terminate();
  }
  catch (std::runtime_error &e)
  {
    octave_stdout << "An error occured while using the portaudio stream:\n";
    octave_stdout << e.what() << "\n";
    octave_stdout << "Error number:  " << err << "\n";
    octave_stdout << "Error message: " << Pa_GetErrorText( err ) << "\n";
    octave_stdout << "Last error from host API: " << Pa_GetLastHostErrorInfo()->errorText << "\n";

    Pa_Terminate();
  }  
    
  return default_inout;
}

DEFUN_DLD(mataa_playrecord_pa19, args, nargout,
          " -- SAMPLED_AUDIO = mataa_playrecord_pa19(TESTSIGNAL, SAMPLERATE,\n"
          "                                          LATENCY,\n" 
          "                                          OUTPUT_DEVICE, INPUT_DEVICE,\n"
          "                                          FRAMES_PER_BUFFER)\n"
          "\n"
          "     Outputs TESTSIGNAL and records SAMPLED_AUDIO. Both input and output\n"
          "     share the sample rate SAMPLERATE (Hz).\n"
          "\n"
          "     Optional arguments:\n"
          "     If LATENCY is given and greater than zero, the portaudio library is\n"
          "     advised to use this latency (seconds).\n"
          "     OUTPUT_DEVICE and INPUT_DEVICE are integers...todo\n"
          "     If FRAMES_PER_BUFFER is given and greater than zero, the portaudio\n"
          "     library is advised to use this number of frames per buffer.\n"
          "\n"
          "\n"
          " -- DEFAULT_DEVICE_INFO = mataa_playrecord_pa19()\n"
          " -- DEFAULT_DEVICE_INFO = mataa_playrecord_pa19(1)\n"
          "\n"
          "     Returns a struct describing the default audio device. In case there is\n"
          "     an argument, all devices' properties are listed on standard output.\n"
         )
{
  int nargin = args.length();

  if (nargout == 1 && nargin >= 2)
  {
    Matrix testsignal = args(0).matrix_value();
    
    // audacity uses 100ms by default
    double latency = -1;
    if (nargin > 2 && args(2).double_value() > 0)
      latency = args(2).double_value();        
    
    int outputdevice = -1;
    int inputdevice  = -1;
    if (nargin > 3 && args(3).double_value() > 0)
      outputdevice = args(3).double_value();    
    if (nargin > 4 && args(4).double_value() > 0)
      inputdevice = args(4).double_value();        
    
    // frames per buffer: use something in the 128-1024 range, or use 
    // paFramesPerBufferUnspecified to let portaudio decide.
    // audacity benutzt immer paFramesPerBufferUnspecified
    unsigned long framesPerBuffer = paFramesPerBufferUnspecified;
    if (nargin > 5 && args(5).double_value() > 0)
      framesPerBuffer = args(5).double_value();

    octave_value_list retval;
    retval(0) = TestTonePA19_main(args(1).double_value(),
                                  testsignal,
                                  outputdevice,
                                  inputdevice,                                  
                                  framesPerBuffer,
                                  latency);
    
    return retval;
  }
  else 
  {
    octave_value_list retval;
    int nList = nargin;
    retval(0) = TestDevicesPA19(nList);
    return retval;
  }
}
