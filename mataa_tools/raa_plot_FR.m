function H = raa_plot_FR(cIR, firstfigurenum=1, fixed_at=[], plot_phase=1,smooth_interval=-1)
  % function raa_plot_FR(cIR, firstfigurenum=1, fixed_at=[], plot_phase=1,smooth_interval=-1)
  %
  %     Plot frequency response
  %
  %
  %     'fixed_at' can be [], or a vector with one element [frequency] or two 
  %     elements [frequency magnitude] where all responses will be shifted to.
  % 
  %     smooth_interval: width of octave band used for smoothing
  %
  %     If a measurement contains 'MIB' in its 'tags' structure field (cell 
  %     array of strings) the measurement is assumed to be of "microphone in box" 
  %     type and the magnitude will be corrected accordingly. See
  %     
  %       R. H. Small, "Simplified Loudspeaker Measurements at Low Frequencies," 
  %       I. Audio Eng. Soc., vol. 20, pp. 28-33 (Jan./Feb. 1972).
  %  
  %     and 
  %
  %      - Measuring Loudspeaker Low-Frequency Response
  %        Joe D'Appolito
  %        audioxpress 2018
  %        https://audioxpress.com/article/measuring-loudspeaker-low-frequency-response
  %      - Measuring Loudspeaker Low-Frequency Response
  %        Joe D'Appolito
  %        http://www.audiomatica.com/wp/wp-content/uploads/Testing-Loudspeakers-at-low-Frequencies-with-CLIO.pdf
  %        This differs from the audioxpress article above!
  %      - Low-Frequency Loudspeaker Assessment by Nearfield Sound-Pressure Measurement
  %        D. B. KEELE, JR
  %        JOURNAL OF THE AUDIO ENGINEERING SOCIETY, APRIL 1974, VOLUME 22, NUMBER 3

  
  
  % This file is part of MATAA.
  % Copyright (C) 2020 Jens W. Wulf.
  
  if iscell(cIR) == 0
    cIR = {cIR};
  end  
  cFR = {};
  lw = mataa_settings('plot_linewidth');
    
  H = mataa_figname(firstfigurenum+0, 'mag');
  cLegend = {};
  clf
  hold on  
  for i1=1:length(cIR)
    m = cIR{i1};
    [fr.mag,fr.phase,fr.f] = mataa_IR_to_FR(m.h, m.fs);
    
    if smooth_interval > 0
      [fr.mag, fr.phase, fr.f] = mataa_FR_smooth(fr.mag, fr.phase, fr.f, smooth_interval);
    end

    if isfield(m, 'cal') && isfield(m.cal, 'SENSOR')
      fr.mag   -= interp1(m.cal.SENSOR.transfer.f, m.cal.SENSOR.transfer.gain,  fr.f);
      fr.phase -= interp1(m.cal.SENSOR.transfer.f, m.cal.SENSOR.transfer.phase, fr.f);
    end

    if ismember('MIB', m.tags) % Correction for microphone-in-box
      f0 = 10;
      fr.mag += 40*log(fr.f/f0)/log(10);
    end      

    switch length(fixed_at)
      case 2
        off = fixed_at(2) - interp1(fr.f, fr.mag, fixed_at(1));
      case 1
        off = 0 - interp1(fr.f, fr.mag, fixed_at(1));
      otherwise
        off = 0;
    end
    
    semilogx(fr.f, fr.mag+off, 'linewidth', lw);
    cFR{i1} = fr;
    cLegend{i1} = mataa_convert_plotnames(m.name);
  end
  hold off
  legend(cLegend, "location", mataa_settings('plot_legendpos_mag'))
  xlabel('Frequency / Hz')
  ylabel('Magnitude / dB')
  grid on

  if plot_phase
    mataa_figname(firstfigurenum+1, 'phase');
    clf
    hold on
    for i1=1:length(cIR)   
      semilogx(cFR{i1}.f, cFR{i1}.phase, ['-;' cLegend{i1} ';'], 'linewidth', lw);
    end
    hold off
    xlabel('Frequency / Hz')
    ylabel('Phase / °')
    grid on
  end
end
