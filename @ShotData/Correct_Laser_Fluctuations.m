function Correct_Laser_Fluctuations(SDO,shotEnergies)
  t1 = tic;
  % sanity check pulse energy fluctuations
  ppeStd = std(shotEnergies)./mean(shotEnergies)*100; % std in percent of mean
  if ppeStd >= 100
    SDO.VPrintF('\n')
    warnStr = sprintf('Pulse energy fluctuations are HUGE (%2.1fperc.)!\n',ppeStd);
    SDO.Verbose_Warn(warnStr);
    SDO.Verbose_Warn('Laser fluctuation correction NOT applied!\n');
    return;
  elseif ppeStd > 25 && ppeStd < 100
    warnStr = sprintf('Pulse energy fluctuations are high (%2.1fperc.)!\n',ppeStd);
    SDO.Verbose_Warn(warnStr);
    SDO.Verbose_Warn('What have you done?!?');
  end
  shotEnergies = shotEnergies./mean(shotEnergies); % center mean at 1
  SDO.VPrintF('Correcting laser fluctuations...');
  SDO.raw = bsxfun(@times,SDO.raw,1./shotEnergies');
  SDO.Done(t1);
end
