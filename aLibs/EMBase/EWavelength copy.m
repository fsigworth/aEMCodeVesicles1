function [lambda, sigma]=EWavelength(kV)
% function [lambda, sigma]=EWavelength(kV)
% Compute the electron wavelength lambda (in angstroms) 
% and the interaction parameter sigma (in radians/V.angstrom)
% given the electron energy kV in kilovolts.
% Uses the relativistic formula 4.3.1.27 in International Tables.  The
% interaction parameter is from eqn. (5.6) of Kirkland 2010.

lambda=12.2639./sqrt(kV*1000+0.97845*kV.^2);

if nargout>1
    u0=511;  % electron rest energy in kilovolts
    sigma=2*pi/(lambda*kV*1000)*(u0+kV)/(2*u0+kV);
end;