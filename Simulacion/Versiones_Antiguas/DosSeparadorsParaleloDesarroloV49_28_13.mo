model DosSeparadorsParaleloDesarroloV49_28_13
  parameter Real V_sep = 17;
  parameter Real Q_agua = 83;        // caudal horario
  parameter Real Q_petroleo = 20;    // caudal horario

  // Setpoints de control [% del volumen del separador]
  parameter Real SP_general  = 75;
  parameter Real SP_petroleo = 54;

  // Controladores PI diferenciados
  Modelica.Blocks.Continuous.PI pidSep1General(k=1.0, T=180);
  Modelica.Blocks.Continuous.PI pidSep1Petroleo(k=1.6, T=120);
  Modelica.Blocks.Continuous.PI pidSep2General(k=1.0, T=180);
  Modelica.Blocks.Continuous.PI pidSep2Petroleo(k=1.6, T=120);

  // Coeficientes de válvula y seguridad
  parameter Real Kv_agua = 3.0;
  parameter Real Kv_petroleo = 3.0;
  parameter Real Kseg = 8.0;
  parameter Real beta = 0.5;   // factor de refuerzo proporcional

  model Separador
    parameter Real V = 17;
    parameter Real Kseg_sep = 8.0;

    input Real Q_in_agua;
    input Real Q_in_petroleo;
    input Real Q_out_agua;
    input Real Q_out_petroleo;

    Real nivelAgua(start=0.0);
    Real nivelPetroleo(start=0.0);

    Real nivelGeneral;
    Real nivelAgua_pct;
    Real nivelPetroleo_pct;
    Real nivelGeneral_pct;

    Real Q_seguridad;
  equation
    // Balance dinámico
    der(nivelAgua)     = (Q_in_agua - Q_out_agua)/3600;
    der(nivelPetroleo) = (Q_in_petroleo - Q_out_petroleo)/3600;

    nivelGeneral      = nivelAgua + nivelPetroleo;

    // Escalado en %
    nivelAgua_pct     = (nivelAgua/V)*100;
    nivelPetroleo_pct = (nivelPetroleo/V)*100;
    nivelGeneral_pct  = (nivelGeneral/V)*100;

    // Caudal de seguridad: actúa si el nivel supera 85%
    Q_seguridad = Kseg_sep * max(0, (nivelGeneral_pct - 85));
  end Separador;

  // Instancias con Kseg pasado como parámetro
  Separador sep1(V=V_sep, Kseg_sep=Kseg);
  Separador sep2(V=V_sep, Kseg_sep=Kseg);

equation
  // División de caudales de entrada
  sep1.Q_in_agua     = Q_agua/2;
  sep1.Q_in_petroleo = Q_petroleo/2;
  sep2.Q_in_agua     = Q_agua/2;
  sep2.Q_in_petroleo = Q_petroleo/2;

  // Señales de control
  pidSep1General.u   = sep1.nivelGeneral_pct - SP_general;
  pidSep1Petroleo.u  = sep1.nivelPetroleo_pct - SP_petroleo;
  pidSep2General.u   = sep2.nivelGeneral_pct - SP_general;
  pidSep2Petroleo.u  = sep2.nivelPetroleo_pct - SP_petroleo;

  // Caudales de salida reforzados
  sep1.Q_out_agua     = Kv_agua * max(0, pidSep1General.y) * (sep1.nivelAgua/V_sep)
                        * (1 + beta*(sep1.nivelGeneral_pct - SP_general)/SP_general)
                        + sep1.Q_seguridad;
  sep1.Q_out_petroleo = Kv_petroleo * max(0, pidSep1Petroleo.y) * (sep1.nivelPetroleo/V_sep)
                        * (1 + beta*(sep1.nivelPetroleo_pct - SP_petroleo)/SP_petroleo);

  sep2.Q_out_agua     = Kv_agua * max(0, pidSep2General.y) * (sep2.nivelAgua/V_sep)
                        * (1 + beta*(sep2.nivelGeneral_pct - SP_general)/SP_general)
                        + sep2.Q_seguridad;
  sep2.Q_out_petroleo = Kv_petroleo * max(0, pidSep2Petroleo.y) * (sep2.nivelPetroleo/V_sep)
                        * (1 + beta*(sep2.nivelPetroleo_pct - SP_petroleo)/SP_petroleo);

end DosSeparadorsParaleloDesarroloV49_28_13;
