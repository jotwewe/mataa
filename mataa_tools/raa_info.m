function raa_info(cellarray_or_one_measurement)
  % function raa_info(cellarray_or_one_measurement)
  %     Show information about one or more measurements created with raa_measure_speaker
    
  % This file is part of MATAA.
  % Copyright (C) 2020 Jens W. Wulf.

  if iscell(cellarray_or_one_measurement)
    cell_alles = cellarray_or_one_measurement;
  else
    cell_alles = {cellarray_or_one_measurement};
  end
  
  for i=1:length(cell_alles)    
    if isfield(cell_alles{i}, 'res')
      m = cell_alles{i}.res;
    else
      m = cell_alles{i};
    end
    fprintf(stdout(), '%s %s\n', strftime('%d.%m.%Y %H:%M:%S', localtime(m.time)), m.name);
    if isfield(m, 'padding_duration')
      fprintf(stdout(), '  padding_duration=%i ms\n', m.padding_duration);
    end
    
    if isfield(m, 'tags') && length(m.tags) > 0
      fprintf(stdout(), '  Tags:');
      for i2=1:length(m.tags)
        fprintf(stdout(), ' %s', m.tags{i2});
      end
      fprintf(stdout(), '\n');
    end
    
    if isfield(m, 'fr')
      for i2=1:length(m.fr)
        
        if isfield(m.fr{i2}, 'loopback')
          strLoop = num2str(m.fr{i2}.loopback);
        else
          strLoop = '?';
        end
        
        fprintf(stdout(), '  %i measurement(s), fs=%.1f kHz, duration=%.1f s, loopback=%s', length(m.fr{i2}.measurements), m.fr{i2}.fs/1000, length(m.fr{i2}.measurements{1}.dut)/m.fr{i2}.fs, strLoop);
        
        % There always is ref und dut, so this doesn't reveal any information:
        % cm = fieldnames(m.fr{i2}.measurements{1});
        % for i3=1:length(cm)
        %   fprintf(stdout(), ' %s', cm{i3});
        % end
        
        
        fprintf(stdout(), '\n');
      end
    end
    
    if isfield(m, 'imp')
      fprintf(stdout(), '  Contains impedance measurement\n');
      if isfield(m.imp, 'RRef')
        fprintf(stdout(), '    RRef=%.1f Ohm\n', m.imp.RRef);
      end
      if isfield(m.imp, 'interchannel_delay')
        fprintf(stdout(), '    interchannel_delay=%i us\n', m.imp.interchannel_delay*1e6);
      end
    end    
    
  end
end
