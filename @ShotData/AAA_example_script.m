US = ShotData();
US.zCrop = [500 1200];
US.Load_Raw_Data(filePath,'ch1');

US.signalPolarity = -1;
US.raw = US.Apply_Signal_Polarity(US.raw);
