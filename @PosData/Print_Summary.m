% [out] = Print_Summary(Pos,In) @ Pos
% text here
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018
function Print_Summary(Pos)
  Pos.Calculate_Sampled_Pos_Info();
  
  Pos.VPrintF('Sampled position data summary:\n');
  Pos.VPrintF('                   \t[TARGET] \t\t[SAMPLED] \n');
  Pos.VPrintF('   center x|y (mm)  \t%4.1f |  %4.1f\t%4.1f |  %4.1f\n',Pos.ctr,Pos.xSCtr,Pos.ySCtr);
  Pos.VPrintF('   width  x|y (mm)  \t%4.1f |  %4.1f\t%4.1f |  %4.1f\n',Pos.width,Pos.xSWidth,Pos.ySWidth);
  Pos.VPrintF('   roi-x (mm)       \t%4.1f <> %4.1f\t%4.1f <> %4.1f\n',Pos.targetRoi(1:2),Pos.xSRoi(:));
  Pos.VPrintF('   roi-y (mm)       \t%4.1f <> %4.1f\t%4.1f <> %4.1f\n',Pos.targetRoi(3:4),Pos.ySRoi(:));
  Pos.VPrintF('   x-velocity (mm/s)\t       %5.1f \t       %5.1f\n',Pos.targetVel(1),Pos.maxVel(1));
  Pos.VPrintF('   y-velocity (mu/s)\t       %5.1f \t       %5.1f\n',Pos.yVelTarget*1e3,Pos.maxVel(2)*1e3);
  Pos.VPrintF('   max dr x|y (um)  \t       %5.1f \t%4.1f |  %4.1f\n',Pos.dr*1e3,Pos.maxDr(1)*1e3,Pos.maxDr(2)*1e3);
  Pos.VPrintF('   # of B-scans     \t     %5.0f\t\t\t %5.0f\n',Pos.ntargetBscans,Pos.nXSBscans);
  Pos.VPrintF('   B-scans rate (Hz)\t\t\tNA \t\t\t\t %3.2f\n',Pos.bScanRate);
  Pos.VPrintF('   scan time (s)    \t\t   %6.2f \t\t   %6.2f\n',Pos.scanTime,max(Pos.tS));
  Pos.VPrintF('   closeness (um)   \t        NA \t\t\t   %6.2f\n',mean(Pos.closeness)*1e3);
end
