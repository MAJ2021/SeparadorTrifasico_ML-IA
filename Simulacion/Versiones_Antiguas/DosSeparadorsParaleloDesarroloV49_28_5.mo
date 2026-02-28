model DosSeparadorsParaleloDesarroloV49_28_5
  // Volumen útil de cada separador [m3]
  parameter Real V_sep = 17;

  //  Caudales de entrada expresados en m3/hora
  // (equivalente a ~2000 m3/día de agua y ~480 m3/día de petróleo en campo)
  parameter Real Q_agua = 83;        
  parameter Real Q_petroleo = 20;    

  // Setpoints de control [% del volumen del separador]
  parameter Real SP_general  = 75;   // nivel total (agua+oil)
  parameter Real SP_petroleo = 54;   // nivel de petróleo

  // Controladores PI (moderados, ajustados en 49.28.3)
  Modelica.Blocks.Continuous.PI pidSep1General(k=0.8, T=200);
  Modelica.Blocks.Continuous.PI pidSep1Petroleo(k=0.8, T=200);
  Modelica.Blocks.Continuous.PI pidSep2General(k=0.8, T=200);
  Modelica.Blocks.Continuous.PI pidSep2Petroleo(k=0.8, T=200);

  //  Coeficientes de válvula (Kv): representan la capacidad de descarga
  // Se ajustan según la hidráulica real de las válvulas de salida
  parameter Real Kv_agua = 1.0;
  parameter Real Kv_petroleo = 1.0;

  model Separador
    parameter Real V = 17;
    input Real Q_in_agua;       // caudal de entrada agua [m3/h]
    input Real Q_in_petroleo;   // caudal de entrada petróleo [m3/h]
    output Real Q_out_agua;     // caudal de salida agua [m3/h]
    output Real Q_out_petroleo; // caudal de salida petróleo [m3/h]

    // Arranque desde cero
    Real nivelAgua(start=0.0);       // volumen agua [fracción de V]
    Real nivelPetroleo(start=0.0);   // volumen petróleo [fracción de V]

    Real nivelGeneral;               // volumen total [fracción de V]
    Real nivelAgua_pct;              // nivel agua [%]
    Real nivelPetroleo_pct;          // nivel petróleo [%]
    Real nivelGeneral_pct;           // nivel total [%]

    // Descarga de emergencia por rebalse
    Real Q_emergencia(start=0.0);
  equation
    // Balance dinámico de volúmenes
    der(nivelAgua)     = (Q_in_agua - Q_out_agua)/3600 / V;
    der(nivelPetroleo) = (Q_in_petroleo - Q_out_petroleo)/3600 / V;

    nivelGeneral      = nivelAgua + nivelPetroleo;

    // Conversión a %
    nivelAgua_pct     = nivelAgua*100;
    nivelPetroleo_pct = nivelPetroleo*100;
    nivelGeneral_pct  = nivelGeneral*100;

    //  Rebalse físico: si nivel > 100%, se abre descarga de emergencia
    when nivelGeneral_pct > 100 then
      Q_emergencia = (nivelGeneral_pct - 100)*V;  // proporcional al exceso
    elsewhen nivelGeneral_pct <= 100 then
      Q_emergencia = 0;
    end when;
  end Separador;

  Separador sep1(V=V_sep);
  Separador sep2(V=V_sep);

equation
  // División de caudales de entrada entre separadores
  sep1.Q_in_agua     = Q_agua/2;
  sep1.Q_in_petroleo = Q_petroleo/2;
  sep2.Q_in_agua     = Q_agua/2;
  sep2.Q_in_petroleo = Q_petroleo/2;

  // Señales de control
  pidSep1General.u   = sep1.nivelGeneral_pct - SP_general;
  pidSep1Petroleo.u  = sep1.nivelPetroleo_pct - SP_petroleo;
  pidSep2General.u   = sep2.nivelGeneral_pct - SP_general;
  pidSep2Petroleo.u  = sep2.nivelPetroleo_pct - SP_petroleo;

  //  Nueva lógica de válvulas con Kv y rebalse
  sep1.Q_out_agua     = max(0, Kv_agua * pidSep1General.y + sep1.Q_emergencia);
  sep1.Q_out_petroleo = max(0, Kv_petroleo * pidSep1Petroleo.y);

  sep2.Q_out_agua     = max(0, Kv_agua * pidSep2General.y + sep2.Q_emergencia);
  sep2.Q_out_petroleo = max(0, Kv_petroleo * pidSep2Petroleo.y);

end DosSeparadorsParaleloDesarroloV49_28_5;
