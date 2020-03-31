% adapthisteq --------------------------------------------------------------
function Apply_CLAHE(M)
  % Contrast-limited adaptive histogram equalization (CLAHE)
  % enhances the contrast of the grayscale image I by transforming the
  % values using contrast-limited adaptive histogram equalization
  if M.verboseOutput
    jprintf('[adapthisteq] CLAHE contrast enhancement...')
  end
  M.Norm();
  M.xy = adapthisteq(M.xy,'Distribution',M.claheDistr,'NBins',M.claheNBins,...
    'ClipLimit',M.claheLim,'NumTiles',M.claheNTiles);
  M.Norm();
  if M.verboseOutput
    done(toc);
  end
end
