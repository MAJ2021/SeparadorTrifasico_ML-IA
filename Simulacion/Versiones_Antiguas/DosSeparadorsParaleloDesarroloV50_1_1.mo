model DosSeparadorsParaleloDesarroloV50_1_1
  parameter Real V_sep = 17;
  parameter Real Q_agua = 83;
  parameter Real Q_petroleo = 20;

  parameter Real SP_general  = 75;
  parameter Real SP_petroleo = 54;

  // Controladores PID básicos (solo estabilizan)
  Modelica.Blocks.Continuous.PID pidGeneral(k=1.2, Ti=90, Td=8);
  Modelica.Blocks.Continuous.PID pidPetroleo(k=1.8, Ti=45, Td=6);

  // Válvulas con dinámica de segundo orden (oscilación amortiguada)
  Modelica.Blocks.Continuous.SecondOrder valveAgua(w=0.01, D=1.2);
  Modelica.Blocks.Continuous.SecondOrder valvePetroleo(w=0.01, D=1.2);

  // Curvas de válvula no lineales (apertura realista)
  Modelica.Blocks.Tables.CombiTable1D curvaAgua(
    table=[0,0; 0.2,0; 0.5,0.6; 0.8,0.9; 1.0,1.0]);
  Modelica.Blocks.Tables.CombiTable1D curvaPetroleo(
    table=[0,0; 0.2,0; 0.5,0.7; 0.8,0.95; 1.0,1.0]);

  // Niveles
  Real nivelAgua(start=0);
  Real nivelPetroleo(start=0);
  Real nivelGeneral;
  Real nivelAgua_pct;
  Real nivelPetroleo_pct;
  Real nivelGeneral_pct;

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
  curvaAgua.u    = pidGeneral.y;
  valveAgua.u    = curvaAgua.y;

  curvaPetroleo.u= pidPetroleo.y;
  valvePetroleo.u= curvaPetroleo.y;

end DosSeparadorsParaleloDesarroloV50_1_1;
