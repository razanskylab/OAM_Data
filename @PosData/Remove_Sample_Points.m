% Remove_Sample_Points(Pos,keepIdx) @ Pos
% Johannes Rebling, (johannesrebling@gmail.com), 2018

function [] = Remove_Sample_Points(Pos,keepIdx)
  if ~islogical(keepIdx)
    error('keepIdx needs to be logical!');
  end
  if numel(keepIdx) ~= Pos.nShots
    Pos.VPrintF('numel(keepIdx)=%i nShots=%i\n',numel(keepIdx),Pos.nShots);
    error('Size of keepIdx not equal to number of shots!');
  end

  preSize = Pos.nShots;

  if ~isempty(Pos.xS)
    Pos.xS = Pos.xS(keepIdx);
  end
  if ~isempty(Pos.xVel)
    Pos.xVel = Pos.xVel(keepIdx);
  end

  if ~isempty(Pos.yS)
    Pos.yS = Pos.yS(keepIdx);
  end
  if ~isempty(Pos.yVel) && ~isscalar(Pos.yVel)
    Pos.yVel = Pos.yVel(keepIdx);
  end
  if ~isempty(Pos.tS)
    Pos.tS = Pos.tS(keepIdx);
  end

  postSize = Pos.nShots;
  perRemoved =  (1-postSize/preSize)*100;

  % convenience function to plot size in human readable string
  Pos.VPrintF('   Removed %i (%2.1f%%) sample points.\n', preSize-postSize, perRemoved);
end
