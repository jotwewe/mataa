function strOut = mataa_convert_plotnames(strIn)
  % function strOut = mataa_convert_plotnames(strIn)
  %     Replaces _ by \_, because usually filenames contain underscores, but not tex markup.
  
  
  % This file is part of MATAA.
  % Copyright (C) 2020 Jens W. Wulf.
  
  strOut = strrep(strIn, '_', '\_');
end
