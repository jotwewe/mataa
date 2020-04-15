function res = raa_measure_speaker(testsignals, fs, strName='', cTags={}, RRef=0, loopback=1, nrepeat=1, firstfigure=1)
  % function res = raa_measure_speaker(testsignals, fs, strName='', cTags={}, RRef=0,  
  %                              loopback=1, nrepeat=1, firstfigure=1)
  %
  %     Measure frequency response (and optionally impedance) of a speaker or
  %     something else, return results and save them to disk.
  %   
  %
  %     Because levels may need adjustment or one may not be satisfied with every 
  %     measurement, results are plotted after each measurement and the user is asked 
  %     whether this measurement should be saved and the next should start.
  %
  %     Things to watch out for: 
  %       - clipped signals (reduce input volume)
  %       - truncated signals (increase padding_duration or padding_level with mataa_settings)
  %       - distorted signals (reduce output level or microphone amplification)
  %       - switched between impedance and frequency response?
  %
  %     Arguments:
  %
  %     testsignals: signal to output; cell array of vectors
  %     fs         : sampling rate to use
  %     strName    : name to assign to this group of measurements. They will be saved to 
  %                  a file ['raa_' strName '.mat']
  %     cTags      : cell array; any number of strings to tag these measurements with. 
  %                  Other raa_ - functions do special treatment for those tags:
  %                    MIB  : microphone-in-box-measurement
  %     RRef       : value of reference resistor R according to the schematic shown in
  %                  mataa_measure_impedance. There will be no impedance measurement if
  %                  this value is smaller or equal to zero.
  %     loopback   : see mataa_measure_IR
  %     nrepeat    : how often to repeat every measurement for averaging, see N at mataa_measure_IR
  %     firstfigure: some figures will be plotted to enable a first evaluation of the measurement,
  %                  starting at figure number firstfigure.

  
  % This file is part of MATAA.
  % Copyright (C) 2020 Jens W. Wulf.
  
  if length(testsignals) > 0
    figure(firstfigure+0); clf;
    figure(firstfigure+1); clf;
    figure(firstfigure+2); clf;
  end
  if RRef > 0
    figure(firstfigure+3); clf;
  end
  
  res.time = time();
  res.name = strName;
  if ischar(cTags)
    if length(cTags) > 0
      cTags = { cTags };
    else
      cTags = {};
    end
  end
  res.tags = cTags;  
  res.padding_duration = mataa_settings('padding_duration');
  
  res.fr = {};
  for its=1:length(testsignals)
    bDone = 0;
    while bDone == 0
      [h,t,unit,raw] = mataa_measure_IR(testsignals{its}, fs, nrepeat, res.padding_duration, loopback);
      [fr.mag,fr.phase,fr.f] = mataa_IR_to_FR(h,fs);
    
      mataa_figname(firstfigure+0, 'mag/freq');
      semilogx(fr.f, fr.mag);
      grid on;
      xlabel('Frequency / Hz')
      ylabel('Magnitude / dB')
      title(mataa_convert_plotnames(strName))
      
      mataa_figname(firstfigure+1, 'phase/freq');
      semilogx(fr.f, fr.phase);
      grid on;
      xlabel('Frequency / Hz')
      ylabel('Phase / °')
      title(mataa_convert_plotnames(strName))
      
      mataa_figname(firstfigure+2, 'value/time');
      if loopback
        plot(t,raw.measurements{1}.ref, t,raw.measurements{1}.dut)
      else
        plot(t,raw.measurements{1}.dut)
      end
      xlabel('Time / s')
      grid on
      
      fprintf(stdout(), '\n');
      if RRef > 0
        if its == 1
          fprintf(stdout(), ':  Did you remember to switch back from impedance measurement?\n');
        end
        if its == length(testsignals)
          fprintf(stdout(), ':  Remember to switch to impedance measurement before you choose to proceed.\n');
        end
      end      
      bDone = ask_done();
    end
        
    res.fr{length(res.fr)+1} = raw;
  end
  
  if RRef > 0  
    bDone = 0;
    while bDone == 0
      % todo: save raw data?
      res.imp.RRef = RRef;
      res.imp.interchannel_delay = mataa_settings('interchannel_delay');
      %
      [res.imp.mag,res.imp.phase,res.imp.f] = mataa_measure_impedance(10,5000,RRef,fs);
      mataa_figname(firstfigure+3, 'impedance');
      semilogx(res.imp.f, res.imp.mag);
      grid on;
      xlabel('Frequency / Hz')
      ylabel('Impedance / Ohm')
      title(mataa_convert_plotnames(strName))
      
      fprintf(stdout(), '\n');
      if length(testsignals) > 0
        fprintf(stdout(), ':  Did you remember switching to impedance measurement?\n');
        fprintf(stdout(), ':  Remember switching back from impedance measurement before you choose to proceed.\n');
      end      
      bDone = ask_done();
    end
  end
  
  if length(strName) > 0
    strFile = ['raa_' strName '.mat'];
    while exist(strFile, 'file')
      warning(['There already is a file named ' strFile])
      strFile = uiputfile("*.mat", "Save results as", strFile);
      if isnumeric(strFile)
        error('The user opted to cancel.')
      end
    end
    save('-binary', '-zip', strFile, 'res'); 
  end
end

function bDone = ask_done()
  fprintf(stdout(), ":  Hit space to proceed, x to cancel everything, anything else to repeat this measurement.\n");
  fflush(stdout());
  key = kbhit();
  
  switch key
    case 'x'
      error('The user opted to cancel.')
    case ' '
      bDone = 1;
    otherwise
      bDone = 0;
  end
end
