function res = raa_load(strFilename, cal=[])
  % function res = raa_load(strFilename, cal=[])
  %     Load measurement(s) from file and attach calibration information.
    
  % This file is part of MATAA.
  % Copyright (C) 2020 Jens W. Wulf.
  res = load(strFilename).res;
  if length(cal) > 0
    res.cal = cal;
  end
  
  if isfield(res, 'tags') == 0
    res.tags = {};
  end
end
