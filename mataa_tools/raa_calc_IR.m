function cIR = raa_calc_IR(cellarray_or_one_measurement)
  % function cIR = raa_calc_IR(cellarray_or_one_measurement)
  %     Calculate impulse responses of one or more measurements
    
  % This file is part of MATAA.
  % Copyright (C) 2020 Jens W. Wulf.

  if iscell(cellarray_or_one_measurement)
    cell_alles = cellarray_or_one_measurement;
  else
    cell_alles = {cellarray_or_one_measurement};
  end

  cIR = {};  
  for i=1:length(cell_alles)
    if isfield(cell_alles{i}, 'res')
      m = cell_alles{i}.res;
    else
      m = cell_alles{i};
    end
        
    ir = raa_propagate_meta(struct(), m);
    if isfield(m, 'fr')
      for i2=1:length(m.fr)
        ir.fs = m.fr{i2}.fs;
        % Handle averaging:
        hsum = 0;
        for i3=1:length(m.fr{i2}.measurements)
          % Without loopback ref is only available in first repetition:
          if isfield(m.fr{i2}.measurements{i3}, 'ref')
            ref = m.fr{i2}.measurements{i3}.ref;
          end          
          hsum += mataa_calc_IR(ref, m.fr{i2}.measurements{i3}.dut);
        end
        ir.h = hsum / length(m.fr{i2}.measurements);
        %
        cIR{length(cIR)+1} = ir;
      end
    end
  end  
end
