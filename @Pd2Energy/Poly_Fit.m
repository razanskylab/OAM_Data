function Poly_Fit(PDE)
  fitError = zeros(PDE.maxFitOrder,1);
  for iFit = 1:PDE.maxFitOrder
    [~,errorStruct,~] = polyfit(PDE.pdSort,PDE.pmSort,iFit);
    fitError(iFit) = errorStruct.normr;
  end
  [~,bestFit] = min(fitError);

  [PDE.Poly.coefficients,PDE.Poly.errorStruct,PDE.Poly.scaling] = ...
    polyfit(PDE.pdSort,PDE.pmSort,bestFit);

  if PDE.verboseOutput
    fprintf(PDE.outTarget,'[PD2E] Best poly fit order %i\n',bestFit);
  end
end
