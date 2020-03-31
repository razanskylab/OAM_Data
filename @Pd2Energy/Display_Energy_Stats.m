% [] = Display_Energy_Stats(PDE) @ PDE
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function [] = Display_Energy_Stats(PDE)
  shotEnergies = PDE.shotEnergies;

  % PDE has normalized powers, so mean of energy is exactly 1
  % in this case don't print units
  isFakeUnits = (mean(shotEnergies) - 1.0) < 1e-12; % can't use == to account for numeric innacuracy

  nSig = 3;
  minStr = num_to_SI_string(min(shotEnergies),nSig,false,true);
  maxStr = num_to_SI_string(max(shotEnergies),nSig,false,true);
  meanStr = num_to_SI_string(mean(shotEnergies),nSig,false,true);
  vprintf(PDE.verboseOutput,PDE.outTarget,'[PD2E] Shot energies: ');
  if isFakeUnits
    vprintf(PDE.verboseOutput,PDE.outTarget,'Min: %s Max %s Mean: %s\n',...
      minStr,maxStr,meanStr);
  else
    vprintf(PDE.verboseOutput,PDE.outTarget,'Min: %sJ Max %sJ Mean: %sJ\n',...
      minStr,maxStr,meanStr);
  end
end
