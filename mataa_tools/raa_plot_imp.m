function raa_plot_imp(cMeas)
  % function raa_plot_FR(cMeas)
  %
  %     Plot speaker impedance

  
  
  % This file is part of MATAA.
  % Copyright (C) 2020 Jens W. Wulf.
  
  if iscell(cMeas) == 0
    cMeas = {cMeas};
  end  
  lw = mataa_settings('plot_linewidth');
    
  cLegend = {};
  clf
  hold on  
  for i1=1:length(cMeas)
    m = cMeas{i1};    
    semilogx(m.imp.f, m.imp.mag, 'linewidth', lw);
    cLegend{i1} = mataa_convert_plotnames(m.name);
  end
  hold off
  legend(cLegend, "location", "northeast")
  xlabel('Frequency / Hz')
  ylabel('Impedance / Ohm')
  grid on
end
