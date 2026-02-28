within ;
model DosSeparadoresTrifasicosRealistaPerturbaciones_V6

  inner Modelica.Fluid.System system;

  // Parámetros generales
  parameter Real V_sep   = 17.0 "Volumen de cada separador m3";
  parameter Real P_sep   = 3.5e5 "Presión de operación Pa (3,5 bar)";
  parameter Real Rgas    = 287 "Constante gas J/kgK";
  parameter Real Tgas    = 328.15 "Temperatura gas K";

  // --- Separador 1 ---
  Real V_oil1(start=V_sep*0.5, min=0, max=V_sep);
  Real V_water1(start=V_sep*0.2, min=0, max=V_sep);
  Real P_gas1(start=P_sep, min=1e5, max=3.5e5);

  // --- Separador 2 ---
  Real V_oil2(start=V_sep*0.5, min=0, max=V_sep);
  Real V_water2(start=V_sep*0.2, min=0, max=V_sep);
  Real P_gas2(start=P_sep, min=1e5, max=3.5e5);

  // Caudales de entrada base (m³/día → m³/s)
  parameter Real Qin_oil_total   = 456/86400;
  parameter Real Qin_water_total = 2000/86400;
  parameter Real Qin_gas_total   = 5000/86400;

  // Perturbaciones
  Modelica.Blocks.Sources.Step perturbWater(height=Qin_water_total*0.2, startTime=150);
  Modelica.Blocks.Sources.Step perturbOil(height=Qin_oil_total*0.15, startTime=220);
  Modelica.Blocks.Sources.Step perturbGas(height=Qin_gas_total*0.2, startTime=300);

  // Distribución de caudales (ejemplo: 60/40)
  Real Qin_oil1, Qin_oil2;
  Real Qin_water1, Qin_water2;
  Real Qin_gas1, Qin_gas2;

  // Salidas
  Real Qout_oil1, Qout_water1, Qout_gas1;
  Real Qout_oil2, Qout_water2, Qout_gas2;

  // Aperturas de válvulas normalizadas (0–1)
  Real valveOil1, valveWater1, valveGas1;
  Real valveOil2, valveWater2, valveGas2;

  // Controladores PID
  Modelica.Blocks.Continuous.PID pidOil1(k=0.5, Ti=40);
  Modelica.Blocks.Continuous.PID pidWater1(k=0.5, Ti=40);
  Modelica.Blocks.Continuous.PID pidGas1(k=0.2, Ti=20);

  Modelica.Blocks.Continuous.PID pidOil2(k=0.5, Ti=40);
  Modelica.Blocks.Continuous.PID pidWater2(k=0.5, Ti=40);
  Modelica.Blocks.Continuous.PID pidGas2(k=0.2, Ti=20);

  // Setpoints
  Modelica.Blocks.Sources.Constant spOil(k=V_sep*0.5);
  Modelica.Blocks.Sources.Constant spWater(k=V_sep*0.2);
  Modelica.Blocks.Sources.Constant spGas(k=P_sep);

  // --- Variables en porcentaje ---
  // Setpoints en %
  Real spOil_pct, spWater_pct, spGas_pct;
  // Variables controladas en %
  Real V_oil1_pct, V_water1_pct, P_gas1_pct;
  Real V_oil2_pct, V_water2_pct, P_gas2_pct;
  // Aperturas válvulas en %
  Real valveOil1_pct, valveWater1_pct, valveGas1_pct;
  Real valveOil2_pct, valveWater2_pct, valveGas2_pct;

equation
  // --- Entradas con perturbaciones y mínimo positivo ---
  Qin_oil1   = max(1e-6, Qin_oil_total*0.6 + perturbOil.y*0.6);
  Qin_oil2   = max(1e-6, Qin_oil_total*0.4 + perturbOil.y*0.4);

  Qin_water1 = max(1e-6, Qin_water_total*0.6 + perturbWater.y*0.6);
  Qin_water2 = max(1e-6, Qin_water_total*0.4 + perturbWater.y*0.4);

  Qin_gas1   = max(1e-6, (Qin_gas_total*0.6) + perturbGas.y*0.6);
  Qin_gas2   = max(1e-6, (Qin_gas_total*0.4) + perturbGas.y*0.4);

  // --- Balance separador 1 ---
  der(V_oil1)   = Qin_oil1   - Qout_oil1;
  der(V_water1) = Qin_water1 - Qout_water1;
  der(P_gas1)   = (Rgas*Tgas/V_sep) * (Qin_gas1 - Qout_gas1);

pidOil1.u   = V_oil1   - spOil.k;
pidWater1.u = V_water1 - spWater.k;
pidGas1.u   = P_gas1   - spGas.k;



  // Aperturas normalizadas (0–1)
  valveOil1   = min(max(pidOil1.y, 0), 1);
  valveWater1 = min(max(pidWater1.y, 0), 1);
  valveGas1   = min(max(pidGas1.y, 0), 1);

  // Caudales de salida con mínimo positivo
  Qout_oil1   = max(1e-6, valveOil1   * Qin_oil1);
  Qout_water1 = max(1e-6, valveWater1 * Qin_water1);
  Qout_gas1   = max(1e-6, valveGas1   * Qin_gas1);

  // --- Balance separador 2 ---
  der(V_oil2)   = Qin_oil2   - Qout_oil2;
  der(V_water2) = Qin_water2 - Qout_water2;
  der(P_gas2)   = (Rgas*Tgas/V_sep) * (Qin_gas2 - Qout_gas2);

pidOil2.u   = V_oil2   - spOil.k;
pidWater2.u = V_water2 - spWater.k;
pidGas2.u   = P_gas2   - spGas.k;


  // Aperturas normalizadas (0–1)
  valveOil2   = min(max(pidOil2.y, 0), 1);
  valveWater2 = min(max(pidWater2.y, 0), 1);
  valveGas2   = min(max(pidGas2.y, 0), 1);

  // Caudales de salida con mínimo positivo
  Qout_oil2   = max(1e-6, valveOil2   * Qin_oil2);
  Qout_water2 = max(1e-6, valveWater2 * Qin_water2);
  Qout_gas2   = max(1e-6, valveGas2   * Qin_gas2);

  // --- Variables en porcentaje ---
  // Setpoints en %
  spOil_pct   = spOil.k   / V_sep * 100;
  spWater_pct = spWater.k / V_sep * 100;
  spGas_pct   = spGas.k   / P_sep * 100;

  // Variables controladas en %
  V_oil1_pct   = V_oil1   / V_sep * 100;
  V_water1_pct = V_water1 / V_sep * 100;
  P_gas1_pct   = P_gas1   / P_sep * 100;

  V_oil2_pct   = V_oil2   / V_sep * 100;
  V_water2_pct = V_water2 / V_sep * 100;
  P_gas2_pct   = P_gas2   / P_sep * 100;

  // Aperturas válvulas en %
  valveOil1_pct   = valveOil1   * 100;
  valveWater1_pct = valveWater1 * 100;
  valveGas1_pct   = valveGas1   * 100;

  valveOil2_pct   = valveOil2   * 100;
  valveWater2_pct = valveWater2 * 100;
  valveGas2_pct   = valveGas2   * 100;

end DosSeparadoresTrifasicosRealistaPerturbaciones_V6;
