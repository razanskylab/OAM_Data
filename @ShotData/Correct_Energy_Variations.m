% []] = Correct_Energy_Variations(SDO,shotEnergies) @ SDO
% correct each shot by multiplying it with the inverse of the
% corresponding shot energy as provided in shotEnergies
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function [] = Correct_Energy_Variations(SDO,shotEnergies)
  tic;
  dataType = class(SDO.raw); % get data type to later restore it

  if ~SDO.verboseOutput
    SDO.PrintF('Correcting for laser energy variations.');
  else
    SDO.Hor_Div();
    SDO.VPrintF('Correcting for laser energy variations...');
  end
  % cou
  % NOTE not casting to single and back to int is 2x faster, but
  % this is the much safer way of doing it, as otherwise we have to make sure we
  % scale the shot energies to be able to safely use int16!
  SDO.raw = bsxfun(@times,single(SDO.raw),1./shotEnergies);
  % SDO.raw = bsxfun(@times,SDO.raw,1./shotEnergies);

  SDO.raw = cast(SDO.raw,dataType); % restore data type to what it was before
  SDO.Done();
end
