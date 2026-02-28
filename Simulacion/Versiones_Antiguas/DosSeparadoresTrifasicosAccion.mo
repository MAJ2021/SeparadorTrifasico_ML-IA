within ;
model DosSeparadoresTrifasicosEstables
  inner Modelica.Fluid.System system;

  // Parámetros generales
  parameter Real V_sep   = 17.0 "Volumen de cada separador m3";
  parameter Real P_sep   = 3.5e5 "Presión de operación Pa (3,5 bar)";
  parameter Real Rgas    = 287 "Constante gas J/kgK";
  parameter Real Tgas    = 300 "Temperatura gas K";

  // --- Separador 1 ---
  Real V_oil1(start=V_sep*0.45, min=0, max=V_sep);   // cerca del setpoint
  Real V_water1(start=V_sep*0.15, min=0, max=V_sep); // cerca del setpoint
  Real P_gas1(start=3.0e5, min=1e5, max=3.5e5);      // cerca del setpoint

  // --- Separador 2 ---
  Real V_oil2(start=V_sep*0.45, min=0, max=V_sep);
  Real V_water2(start=V_sep*0.15, min=0, max=V_sep);
  Real P_gas2(start=3.0e5, min=1e5, max=3.5e5);

  // Caudales de entrada base (m³/día → m³/s)
  parameter Real Qin_oil_total   = 456/86400;
  parameter Real Qin_water_total = 2000/86400;
  parameter Real Qin_gas_total   = 5000/86400;

  // Distribución de caudales (ejemplo: 60/40)
  Real Qin_oil1 = Qin_oil_total*0.6;
  Real Qin_oil2 = Qin_oil_total*0.4;
  Real Qin_water1 = Qin_water_total*0.6;
  Real Qin_water2 = Qin_water_total*0.4;
  Real Qin_gas1, Qin_gas2;

  // Perturbación en gas (20% extra desde t=300s)
  Modelica.Blocks.Sources.Step perturbGas(height=Qin_gas_total*0.2, startTime=300);

  // Salidas
  Real Qout_oil1, Qout_water1, Qout_gas1;
  Real Qout_oil2, Qout_water2, Qout_gas2;

  // Controladores PID más suaves
  Modelica.Blocks.Continuous.PID pidOil1(k=1, Ti=60);
  Modelica.Blocks.Continuous.PID pidWater1(k=1, Ti=60);
  Modelica.Blocks.Continuous.PID pidGas1(k=0.2, Ti=40);

  Modelica.Blocks.Continuous.PID pidOil2(k=1, Ti=60);
  Modelica.Blocks.Continuous.PID pidWater2(k=1, Ti=60);
  Modelica.Blocks.Continuous.PID pidGas2(k=0.2, Ti=40);

  // Setpoints
  Modelica.Blocks.Sources.Constant spOil(k=V_sep*0.5);
  Modelica.Blocks.Sources.Constant spWater(k=V_sep*0.2);
  Modelica.Blocks.Sources.Constant spGas(k=P_sep);

equation
  // Perturbación aplicada al gas
  Qin_gas1 = (Qin_gas_total*0.6) + perturbGas.y*0.6;
  Qin_gas2 = (Qin_gas_total*0.4) + perturbGas.y*0.4;

  // --- Balance separador 1 ---
  der(V_oil1)   = Qin_oil1   - Qout_oil1;
  der(V_water1) = Qin_water1 - Qout_water1;
  der(P_gas1)   = (Rgas*Tgas/V_sep) * (Qin_gas1 - Qout_gas1);

  pidOil1.u   = spOil.k   - V_oil1;
  pidWater1.u = spWater.k - V_water1;
  pidGas1.u   = spGas.k   - P_gas1;

  // Válvulas limitadas (factor 0.05 y saturación)
  Qout_oil1   = min(max(0, pidOil1.y   * 0.05), Qin_oil1);
  Qout_water1 = min(max(0, pidWater1.y * 0.05), Qin_water1);
  Qout_gas1   = min(max(0, pidGas1.y   * 0.05), Qin_gas1);

  // --- Balance separador 2 ---
  der(V_oil2)   = Qin_oil2   - Qout_oil2;
  der(V_water2) = Qin_water2 - Qout_water2;
  der(P_gas2)   = (Rgas*Tgas/V_sep) * (Qin_gas2 - Qout_gas2);

  pidOil2.u   = spOil.k   - V_oil2;
  pidWater2.u = spWater.k - V_water2;
  pidGas2.u   = spGas.k   - P_gas2;

  Qout_oil2   = min(max(0, pidOil2.y   * 0.05), Qin_oil2);
  Qout_water2 = min(max(0, pidWater2.y * 0.05), Qin_water2);
  Qout_gas2   = min(max(0, pidGas2.y   * 0.05), Qin_gas2);

end DosSeparadoresTrifasicosEstables;
