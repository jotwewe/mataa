function H = mataa_figname(num, strTitle)
  % function mataa_figname(num, strTitle)
  %     Open a figure using figure(num) and set the window title
  
  % This file is part of MATAA.
  % Copyright (C) 2020 Jens W. Wulf.
  
  strName = [num2str(num) ': ' strTitle];
  H = figure(num);
  clf
  set(gcf(), 'Name', strName);
  set(gcf(), 'NumberTitle', 'off');
end
