model DosSeparadorsParaleloDesarroloV49_10
  parameter Real V_sep = 17;
  parameter Real Q_agua = 83;
  parameter Real Q_petroleo = 20;
  parameter Real Q_liquidos = Q_agua + Q_petroleo;
  parameter Real Q_gas = 150;

  // Setpoints (iguales para ambos separadores)
  parameter Real SP_general   = 75 "Setpoint nivel general (%)";
  parameter Real SP_petroleo  = 54 "Setpoint nivel petróleo (%)";

  // Controladores PI (idénticos para ambos)
  Modelica.Blocks.Continuous.PI pidSep1General(k=0.9, T=1600);
  Modelica.Blocks.Continuous.PI pidSep1Petroleo(k=0.9, T=1600);
  Modelica.Blocks.Continuous.PI pidSep2General(k=0.9, T=1600);
  Modelica.Blocks.Continuous.PI pidSep2Petroleo(k=0.9, T=1600);

  // Modelo de separador
  model Separador
    parameter Real V = 17;
    input Real Q_in;
    input Real Q_out;
    Real nivel(start=0.5);
    Real nivel_pct;
    Real nivelPetroleo;
    Real nivelPetroleo_pct;
  equation
    der(nivel) = (Q_in - Q_out)/3600 / V;
    nivel_pct = nivel*100;
    nivelPetroleo = 0.54*nivel;
    nivelPetroleo_pct = nivelPetroleo*100;
    when nivel < 0 then reinit(nivel, 0); end when;
    when nivel > 1 then reinit(nivel, 1); end when;
  end Separador;

  // Instancias de separadores (idénticas)
  Separador sep1(V=V_sep);
  Separador sep2(V=V_sep);

equation
  // Entradas iguales
  sep1.Q_in = Q_liquidos/2;
  sep2.Q_in = Q_liquidos/2;

  // Ambos regulan nivel general y petróleo contra los mismos SP
  pidSep1General.u   = sep1.nivel_pct - SP_general;
  pidSep1Petroleo.u  = sep1.nivelPetroleo_pct - SP_petroleo;
  pidSep2General.u   = sep2.nivel_pct - SP_general;
  pidSep2Petroleo.u  = sep2.nivelPetroleo_pct - SP_petroleo;

  // Salidas reguladas con la misma lógica
  sep1.Q_out = sep1.Q_in * (1 + (pidSep1General.y + pidSep1Petroleo.y)/100);
  sep2.Q_out = sep2.Q_in * (1 + (pidSep2General.y + pidSep2Petroleo.y)/100);

end DosSeparadorsParaleloDesarroloV49_10;
