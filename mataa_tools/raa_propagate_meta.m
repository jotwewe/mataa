function data = raa_propagate_meta(data, in)
  % function data = raa_propagate_meta(data, in)
  %     Propagates some structure fields from in to data.
    
  % This file is part of MATAA.
  % Copyright (C) 2020 Jens W. Wulf.
  
  data.name = in.name;
  if isfield(in, 'tags')
    data.tags = in.tags;
  end
  if isfield(in, 'cal')
    data.cal  = in.cal;
  end
  
end
