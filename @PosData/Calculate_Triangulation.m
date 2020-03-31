% [out] = Calculate_Triangulation(Pos,In) @ Pos
% Output args
% DT - delaunayTriangulation object
% nearIdx - idx of points corresponding to nearest neighbor
% closeness - distance of all sample points to their nearest neighbor
%
% Johannes Rebling, (johannesrebling@gmail.com), 2018


function [DT,nearIdx,closeness] = Calculate_Triangulation(Pos)
  tic;
  Pos.VPrintF('Triangulating sampled x-y points (delaunay)...');

  % FIXME warning stuff only temp. while we don't remove duplicate data points
  s = warning;
  warning('off');
  DT = delaunayTriangulation(double(Pos.xS)',double(Pos.yS)');
  warning(s);

  % calculate nearest neighbor index, so that for each point on the regular
  % grid xReg(i) you get the nearest sampled point as Pos.xS(nearIdx(i))
  Pos.dr = Pos.dr;
  nearIdx = nearestNeighbor(DT,Pos.xReg',Pos.yReg');

  closeness = sqrt((Pos.xS(nearIdx)-Pos.xReg).^2 + ...
    (Pos.yS(nearIdx)-Pos.yReg).^2);

  Pos.DelaunayTri = DT;
  Pos.nearIdx = nearIdx;
  Pos.closeness = closeness;

  Pos.Done();
end
