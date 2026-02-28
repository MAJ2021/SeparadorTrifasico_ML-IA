model DosSeparadorsParaleloDesarroloV49_28_3
  parameter Real V_sep = 17;
  parameter Real Q_agua = 83;
  parameter Real Q_petroleo = 20;

  // Setpoints correctos
  parameter Real SP_general  = 75;
  parameter Real SP_petroleo = 54;

  //  Controladores PI suavizados
  Modelica.Blocks.Continuous.PI pidSep1General(k=0.8, T=200);
  Modelica.Blocks.Continuous.PI pidSep1Petroleo(k=0.8, T=200);
  Modelica.Blocks.Continuous.PI pidSep2General(k=0.8, T=200);
  Modelica.Blocks.Continuous.PI pidSep2Petroleo(k=0.8, T=200);

  model Separador
    parameter Real V = 17;
    input Real Q_in_agua;
    input Real Q_in_petroleo;
    input Real Q_out_agua;
    input Real Q_out_petroleo;

    // Arranque desde cero
    Real nivelAgua(start=0.0);
    Real nivelPetroleo(start=0.0);

    Real nivelGeneral;
    Real nivelAgua_pct;
    Real nivelPetroleo_pct;
    Real nivelGeneral_pct;
  equation
    der(nivelAgua)     = (Q_in_agua - Q_out_agua)/3600 / V;
    der(nivelPetroleo) = (Q_in_petroleo - Q_out_petroleo)/3600 / V;

    nivelGeneral      = nivelAgua + nivelPetroleo;

    // Se mantiene cálculo de % como en baseline
    nivelAgua_pct     = nivelAgua*100;
    nivelPetroleo_pct = nivelPetroleo*100;
    nivelGeneral_pct  = nivelGeneral*100;

    // Reinit sobre estados
    when nivelAgua < 0 then reinit(nivelAgua, 0); end when;
    when nivelPetroleo < 0 then reinit(nivelPetroleo, 0); end when;
    when nivelGeneral > V then
      reinit(nivelAgua, V/2);
      reinit(nivelPetroleo, V/2);
    end when;
  end Separador;

  Separador sep1(V=V_sep);
  Separador sep2(V=V_sep);

equation
  sep1.Q_in_agua     = Q_agua/2;
  sep1.Q_in_petroleo = Q_petroleo/2;
  sep2.Q_in_agua     = Q_agua/2;
  sep2.Q_in_petroleo = Q_petroleo/2;

  pidSep1General.u   = sep1.nivelGeneral_pct - SP_general;
  pidSep1Petroleo.u  = sep1.nivelPetroleo_pct - SP_petroleo;
  pidSep2General.u   = sep2.nivelGeneral_pct - SP_general;
  pidSep2Petroleo.u  = sep2.nivelPetroleo_pct - SP_petroleo;

  // Limitación de caudales ≥ 0
  sep1.Q_out_agua     = max(0, sep1.Q_in_agua * (1 + pidSep1General.y/100));
  sep1.Q_out_petroleo = max(0, sep1.Q_in_petroleo * (1 + pidSep1Petroleo.y/100));

  sep2.Q_out_agua     = max(0, sep2.Q_in_agua * (1 + pidSep2General.y/100));
  sep2.Q_out_petroleo = max(0, sep2.Q_in_petroleo * (1 + pidSep2Petroleo.y/100));

end DosSeparadorsParaleloDesarroloV49_28_3;
