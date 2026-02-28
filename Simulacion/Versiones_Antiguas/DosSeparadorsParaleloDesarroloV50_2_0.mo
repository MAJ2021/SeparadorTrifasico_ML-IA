model DosSeparadorsParaleloDesarroloV50_2_1
  parameter Real V_sep = 17;
  parameter Real Q_agua_in = 83;
  parameter Real Q_petroleo_in = 20;

  parameter Real SP_general  = 75;
  parameter Real SP_petroleo = 54;

  // Resistencias e inercias
  parameter Real R_agua = 0.02;
  parameter Real R_petroleo = 0.03;
  parameter Real C_acop = 0.05;

  // Estados
  Real nivelAgua(start=0);
  Real nivelPetroleo(start=0);

  // Salidas para graficar
  Real nivelGeneral;
  Real nivelAgua_pct;
  Real nivelPetroleo_pct;
  Real nivelGeneral_pct;

  // Caudales de salida
  Real Q_out_agua;
  Real Q_out_petroleo;

  // Funciones de válvula no lineal
  function curvaAgua
    input Real u;
    output Real y;
  algorithm
    if u < 0.2 then
      y := 0;
    elseif u < 0.8 then
      y := (u-0.2)/0.6;
    else
      y := 1.0;
    end if;
  end curvaAgua;

  function curvaPetroleo
    input Real u;
    output Real y;
  algorithm
    if u < 0.3 then
      y := 0;
    elseif u < 0.7 then
      y := (u-0.3)/0.4;
    else
      y := 1.0;
    end if;
  end curvaPetroleo;

equation
  // Balances dinámicos
  der(nivelAgua) =
     (Q_agua_in/2 - Q_out_agua)/3600
     - C_acop*(nivelPetroleo_pct - SP_petroleo)/100;

  der(nivelPetroleo) =
     (Q_petroleo_in/2 - Q_out_petroleo)/3600
     - C_acop*(nivelAgua_pct - SP_general)/100;

  // Cálculo de niveles
  nivelGeneral      = nivelAgua + nivelPetroleo;
  nivelAgua_pct     = (nivelAgua/V_sep)*100;
  nivelPetroleo_pct = (nivelPetroleo/V_sep)*100;
  nivelGeneral_pct  = (nivelGeneral/V_sep)*100;

  // Descargas definidas por válvulas no lineales
  Q_out_agua     = curvaAgua(nivelGeneral_pct/100) * (nivelAgua/R_agua);
  Q_out_petroleo = curvaPetroleo(nivelPetroleo_pct/100) * (nivelPetroleo/R_petroleo);

end DosSeparadorsParaleloDesarroloV50_2_1;
