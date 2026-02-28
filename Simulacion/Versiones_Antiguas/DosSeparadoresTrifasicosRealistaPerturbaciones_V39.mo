model DosSeparadoresTrifasicosRealistaPerturbaciones_V39
  import Modelica.Blocks.Continuous.PID;
  import Modelica.Blocks.Continuous.FirstOrder;

  // --- Parámetros comunes ---
  parameter Real tauRec = 20 "Constante de tiempo de recuperación común";
  parameter Real Krec   = 0.05 "Ganancia de recuperación común";

  // --- Variables de proceso: Separador 1 ---
  Real nivelGas_sep1(start=50), nivelAgua_sep1(start=50), nivelPetroleo_sep1(start=50);
  Real caudalEntrada_sep1;
  Real caudalSalidaGas_sep1, caudalSalidaAgua_sep1, caudalSalidaPetroleo_sep1;

  // --- Variables de proceso: Separador 2 ---
  Real nivelGas_sep2(start=50), nivelAgua_sep2(start=50), nivelPetroleo_sep2(start=50);
  Real caudalEntrada_sep2;
  Real caudalSalidaGas_sep2, caudalSalidaAgua_sep2, caudalSalidaPetroleo_sep2;

  // --- Controladores PID con retardo: Separador 1 ---
  PID pidGas_sep1(k=1, Ti=30, Td=5);
  PID pidAgua_sep1(k=1, Ti=25, Td=4);
  PID pidPetroleo_sep1(k=1, Ti=28, Td=6);

  FirstOrder delayGas_sep1(T=3);
  FirstOrder delayAgua_sep1(T=3);
  FirstOrder delayPetroleo_sep1(T=3);

  // --- Controladores PID con retardo: Separador 2 ---
  PID pidGas_sep2(k=1, Ti=30, Td=5);
  PID pidAgua_sep2(k=1, Ti=25, Td=4);
  PID pidPetroleo_sep2(k=1, Ti=28, Td=6);

  FirstOrder delayGas_sep2(T=3);
  FirstOrder delayAgua_sep2(T=3);
  FirstOrder delayPetroleo_sep2(T=3);

equation
  // --- Definición de entradas (con perturbación en sep1) ---
  caudalEntrada_sep1 = if time < 2000 then 100 else 60;
  caudalEntrada_sep2 = 100;

  // --- Recuperación generalizada: Separador 1 ---
  der(nivelGas_sep1)      = Krec*(caudalEntrada_sep1 - caudalSalidaGas_sep1) - nivelGas_sep1/tauRec;
  der(nivelAgua_sep1)     = Krec*(caudalEntrada_sep1 - caudalSalidaAgua_sep1) - nivelAgua_sep1/tauRec;
  der(nivelPetroleo_sep1) = Krec*(caudalEntrada_sep1 - caudalSalidaPetroleo_sep1) - nivelPetroleo_sep1/tauRec;

  // --- Recuperación generalizada: Separador 2 ---
  der(nivelGas_sep2)      = Krec*(caudalEntrada_sep2 - caudalSalidaGas_sep2) - nivelGas_sep2/tauRec;
  der(nivelAgua_sep2)     = Krec*(caudalEntrada_sep2 - caudalSalidaAgua_sep2) - nivelAgua_sep2/tauRec;
  der(nivelPetroleo_sep2) = Krec*(caudalEntrada_sep2 - caudalSalidaPetroleo_sep2) - nivelPetroleo_sep2/tauRec;

  // --- Control con retardo: Separador 1 ---
  pidGas_sep1.u       = nivelGas_sep1;
  delayGas_sep1.u     = pidGas_sep1.y;
  caudalSalidaGas_sep1 = delayGas_sep1.y;

  pidAgua_sep1.u      = nivelAgua_sep1;
  delayAgua_sep1.u    = pidAgua_sep1.y;
  caudalSalidaAgua_sep1 = delayAgua_sep1.y;

  pidPetroleo_sep1.u  = nivelPetroleo_sep1;
  delayPetroleo_sep1.u = pidPetroleo_sep1.y;
  caudalSalidaPetroleo_sep1 = delayPetroleo_sep1.y;

  // --- Control con retardo: Separador 2 ---
  pidGas_sep2.u       = nivelGas_sep2;
  delayGas_sep2.u     = pidGas_sep2.y;
  caudalSalidaGas_sep2 = delayGas_sep2.y;

  pidAgua_sep2.u      = nivelAgua_sep2;
  delayAgua_sep2.u    = pidAgua_sep2.y;
  caudalSalidaAgua_sep2 = delayAgua_sep2.y;

  pidPetroleo_sep2.u  = nivelPetroleo_sep2;
  delayPetroleo_sep2.u = pidPetroleo_sep2.y;
  caudalSalidaPetroleo_sep2 = delayPetroleo_sep2.y;

end DosSeparadoresTrifasicosRealistaPerturbaciones_V39;
