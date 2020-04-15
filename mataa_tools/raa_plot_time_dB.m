function res = raa_plot_time_dB(cellarray_or_one_measurement, lim_dB=-50)
  % function raa_plot_time_dB(cellarray_or_one_measurement)
  %     Average burst measurement(s) and display them,
  %     see 
  %     Shaped Tone-Burst Testing, SIEGFRIED LlNKWITZ,
  %     JOURNAL OF THE AUDIO ENGINEERING SOCIETY, 1980 APRIL, VOLUME 28, NUMBER 4

  % This file is part of MATAA.
  % Copyright (C) 2020 Jens W. Wulf.
  
  lw = mataa_settings('plot_linewidth');

  if iscell(cellarray_or_one_measurement)
    cell_alles = cellarray_or_one_measurement;
  else
    cell_alles = {cellarray_or_one_measurement};
  end

  timeref.dut = [];
  timeref.fs  = 0;
  nPlot = 1;

  level_korr = 0.05;
  vtOff=[];

  clf
  hold on  
  for i=1:length(cell_alles)    
    if isfield(cell_alles{i}, 'res')
      m = cell_alles{i}.res;
    else
      m = cell_alles{i};
    end
    if isfield(m, 'fr')
      for i2=1:length(m.fr)                
        vMean = [];
        for i3=1:length(m.fr{i2}.measurements)
          dut = m.fr{i2}.measurements{i3}.dut;

          if isfield(m.fr{i2}.measurements{i3}, 'tOff')
            iOff = int32(round(m.fr{i2}.measurements{i3}.tOff * m.fr{i2}.fs));
          else
            warning(['No time offset given for ' m.name '(' num2str(i2) ',' num2str(i3) ')'])
            iOff = 0;
          end
          
          if i3 == 1
            vMean = circshift(dut, iOff);
          else
            vMean += circshift(dut, iOff);
          end
        end
        
        dut = vMean / length(m.fr{i2}.measurements);
        t   = [0:length(dut)-1] / m.fr{i2}.fs;
        
        if length(vtOff) > 0
          tOff = vtOff(nPlot);
        else
          if length(timeref.dut) == 0
            tOff = 0;
          else
            b = abs(dut-mean(dut));
            l = find(b < level_korr);
            b(l) = 0;
            maxlag = 0.2*m.fr{i2}.fs;
            xcorr_res = xcorr(timeref.dut, b, maxlag);
            [dummy, idx] = max(xcorr_res);
            iOff = int32(interp1([1 2*maxlag+1], [-maxlag maxlag], idx));
            tOff = double(iOff) / m.fr{i2}.fs;
          end
        end

        if true
          d.y = 20*log10(abs(dut-mean(dut)));
          d.x = t + tOff;
          d.l = find(d.y > lim_dB);
                    
          plot(d.x(d.l), d.y(d.l), ['-;' mataa_convert_plotnames(m.name) '(' num2str(i2) ',avg);']);
        else
          plot(t+tOff, dut, ['-;' mataa_convert_plotnames(m.name) '(' num2str(i2) ',avg);']);
        end
        
        if length(timeref.dut) == 0
          timeref.dut = abs(dut-mean(dut));
          l = find(timeref.dut < level_korr);
          timeref.dut(l) = 0;
        end
        nPlot += 1;
      end
    end
  end
  hold off
  xlabel('Time / s')
  ylabel('Magnitude / dB')
  grid on
end
