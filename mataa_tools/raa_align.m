function raa_align(strFile)
  % function raa_align(strFile)
  %     Load strFile. In case of measurements to be averaged: calculate 
  %     time offsets, display measurements, save time offsets back to 
  %     strFile in case the user wants to.
  
  
  % This file is part of MATAA.
  % Copyright (C) 2020 Jens W. Wulf.
  
  res = raa_load(strFile);
  
  nEdit = 0;

  if isfield(res, 'fr')
    for i2=1:length(res.fr)
      if length(res.fr{i2}.measurements) > 1
        clf
        hold on
        v_tOff = [];
        for i3=1:length(res.fr{i2}.measurements)
          dut = res.fr{i2}.measurements{i3}.dut;
          t = [0:length(dut)-1] / res.fr{i2}.fs;
          
          if i3 == 1
            iOff = 0
          else
            maxlag = 0.1*res.fr{i2}.fs;
            [dummy, idx] = max(xcorr(res.fr{i2}.measurements{1}.dut, dut, maxlag));
            iOff = int32(interp1([1 2*maxlag+1], [-maxlag maxlag], idx));
          end
          tOff = double(iOff) / res.fr{i2}.fs
          v_tOff = [v_tOff, tOff];
          
          plot(t+tOff, dut, ['-;' mataa_convert_plotnames(res.name) '(' num2str(i2) ',' num2str(i3) ');']);
        end
        hold off
        xlabel('Time / s');
        grid on
        drawnow();
        
        fprintf(stdout(), '%i measurement(s), fs=%.1f kHz, duration=%.1f s.\n', length(res.fr{i2}.measurements), res.fr{i2}.fs/1000, length(res.fr{i2}.measurements{1}.dut)/res.fr{i2}.fs);
        if menu(sprintf('Align .fr{%i} as plotted?\n', i2), {'yes', 'no'}) == 1
          nEdit += 1;
          for i3=1:length(res.fr{i2}.measurements)
            res.fr{i2}.measurements{i3}.tOff = v_tOff(i3);
          end
        end
        
      end
    end
  end

  if nEdit
    save('-binary', '-zip', strFile, 'res');     
  end
end
