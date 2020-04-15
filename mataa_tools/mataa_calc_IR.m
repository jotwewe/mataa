function h = mataa_calc_IR(ref, dut)
  % -- function h = mataa_calc_IR(ref, dut)
  %     Calculate impulse response 'h' from input signal 'ref' and output signal 'dut'.
  
  %
  % DISCLAIMER:
  % This file is part of MATAA.
  %
  % Code moved from mataa_measure_IR.m, Copyright (C) 2006, 2007, 2008,2015 Matthias S. Brennwald.
  
  l = length (ref);
  uu = flipud ([1:l]'/l);
	
  dut = [ dut ; uu*dut(end) ];
  ref = [ ref ; uu*ref(end) ];		
  H = fft(dut) ./ fft(ref) ; % normalize by 'ref' signal

  H(1) = 0; % remove DC
	
  h = ifft (H);	
  h = h(1:l); % the other half is redundant since the signal is real
  h = abs (h) .* sign (real(h)); % turn it back to the real-axis (complex part is much smaller than real part, so this works fine)  
end
