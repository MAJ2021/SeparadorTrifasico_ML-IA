model DosSeparadorsParaleloDesarroloV50_1_2
  parameter Real V_sep = 17;
  parameter Real Q_agua = 83;
  parameter Real Q_petroleo = 20;

  parameter Real SP_general  = 75;
  parameter Real SP_petroleo = 54;

  // Controladores PID básicos
  Modelica.Blocks.Continuous.PID pidGeneral(k=1.2, Ti=90, Td=8);
  Modelica.Blocks.Continuous.PID pidPetroleo(k=1.8, Ti=45, Td=6);

  // Válvulas con dinámica de segundo orden (oscilación amortiguada)
  Modelica.Blocks.Continuous.SecondOrder valveAgua(w=0.01, D=1.2);
  Modelica.Blocks.Continuous.SecondOrder valvePetroleo(w=0.01, D=1.2);

  // Niveles
  Real nivelAgua(start=0);
  Real nivelPetroleo(start=0);
  Real nivelGeneral;
  Real nivelAgua_pct;
  Real nivelPetroleo_pct;
  Real nivelGeneral_pct;

  // Funciones de apertura no lineal (reemplazo de CombiTable1D)
  function curvaAgua
    input Real u;
    output Real y;
  algorithm
    if u < 0.2 then
      y := 0;
    elseif u < 0.5 then
      y := 0.6*(u-0.2)/0.3;
    elseif u < 0.8 then
      y := 0.6 + 0.3*(u-0.5)/0.3;
    else
      y := 0.9 + 0.1*(u-0.8)/0.2;
    end if;
  end curvaAgua;

  function curvaPetroleo
    input Real u;
    output Real y;
  algorithm
    if u < 0.2 then
      y := 0;
    elseif u < 0.5 then
      y := 0.7*(u-0.2)/0.3;
    elseif u < 0.8 then
      y := 0.7 + 0.25*(u-0.5)/0.3;
    else
      y := 0.95 + 0.05*(u-0.8)/0.2;
    end if;
  end curvaPetroleo;

equation
  // Balances dinámicos con acoplamiento agua–petróleo
  der(nivelAgua)     = (Q_agua/2 - valveAgua.y)/3600
                       - 0.05*(nivelPetroleo_pct - SP_petroleo);
  der(nivelPetroleo) = (Q_petroleo/2 - valvePetroleo.y)/3600
                       - 0.05*(nivelAgua_pct - SP_general);

  nivelGeneral      = nivelAgua + nivelPetroleo;
  nivelAgua_pct     = (nivelAgua/V_sep)*100;
  nivelPetroleo_pct = (nivelPetroleo/V_sep)*100;
  nivelGeneral_pct  = (nivelGeneral/V_sep)*100;

  // Controladores
  pidGeneral.u   = nivelGeneral_pct - SP_general;
  pidPetroleo.u  = nivelPetroleo_pct - SP_petroleo;

  // Válvulas con curva no lineal + segundo orden
  valveAgua.u    = curvaAgua(pidGeneral.y);
  valvePetroleo.u= curvaPetroleo(pidPetroleo.y);

end DosSeparadorsParaleloDesarroloV50_1_2;
