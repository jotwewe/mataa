function spaced_freqs = mataa_octspace(fmin, fmax, per_oct)
  % -- spaced_freqs = mataa_octspace(fmin, fmax, per_oct)
  %     Returns a vector of frequencies between fmin and fmax 
  %     with per_oct items per octave.
  
  % This file is part of MATAA.
  % Copyright (C) 2020 Jens W. Wulf.

  octs = log(fmax/fmin) / log(2);
  spaced_freqs = logspace(log10(fmin), log10(fmax), ceil(octs * per_oct)+1);
end
