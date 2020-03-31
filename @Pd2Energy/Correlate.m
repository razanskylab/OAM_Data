% [corValues] = Correlate(Pd2Energy)
% correlate converted pd shots (in a.u.) to measured pm shots and get correlation
% coefficients
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function [corValues] = Correlate(PDE)
  corValues(1) = corr(PDE.pd,PDE.pm,'Type','Pearson'); % 'Pearson' - linear correlation coefficient
  corValues(2) = corr(PDE.pd,PDE.pm,'Type','Spearman'); % 'Spearman' computes Spearman's rho
  % https://en.wikipedia.org/wiki/Spearman%27s_rank_correlation_coefficient
  PDE.corValues = corValues;
  if PDE.verboseOutput
    fprintf(PDE.outTarget,'[PD2E] Checking PD to PM correlation: %.2f\n',corValues(1));
    fprintf(PDE.outTarget,'       Linear correlation:   %.2f\n',corValues(1));
    fprintf(PDE.outTarget,'       Spearman correlation: %.2f\n',corValues(2));
  end
end
