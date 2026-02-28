within ;
model SeparadorTrifasicoControlado
  inner Modelica.Fluid.System system;

  // Parámetros
  parameter Real V_total = 17.3 "Volumen separador m3";
  parameter Real P_sep   = 3.5e5 "Presión separador Pa";

  // Estados dinámicos
  Real V_oil(start=V_total*0.54, min=0);
  Real V_water(start=V_total*0.21, min=0);
  Real P_gas(start=P_sep, min=1e5, max=1e6);

  // Caudales de entrada (m3/s)
  Real Qin_oil;
  parameter Real Qin_water = 2000/86400;
  parameter Real Qin_gas   = 5000/86400;

  // Caudales de salida (limitados a ≥ 0)
  Real Qout_oil;
  Real Qout_water;
  Real Qout_gas;

  // Controladores PID (suaves)
  Modelica.Blocks.Continuous.PID pidOil(k=0.5, Ti=100, Td=0);
  Modelica.Blocks.Continuous.PID pidWater(k=0.5, Ti=100, Td=0);
  Modelica.Blocks.Continuous.PID pidGas(k=0.01, Ti=300, Td=0);

  // Setpoints
  Modelica.Blocks.Sources.Constant spOil(k=V_total*0.54);
  Modelica.Blocks.Sources.Constant spWater(k=V_total*0.21);
  Modelica.Blocks.Sources.Constant spGas(k=P_sep);

  // Perturbación en petróleo
  Modelica.Blocks.Sources.Step perturbOil(height=0.002, startTime=200);

equation
  // Caudal de petróleo con perturbación
  Qin_oil = 456/86400 + perturbOil.y;

  // Balances líquidos
  der(V_oil)   = Qin_oil   - Qout_oil;
  der(V_water) = Qin_water - Qout_water;

  // Balance de presión gas (simplificado)
  der(P_gas) = (Qin_gas - Qout_gas) * 1e4;

  // PID entradas
  pidOil.u   = spOil.k   - V_oil;
  pidWater.u = spWater.k - V_water;
  pidGas.u   = spGas.k   - P_gas;

  // PID salidas → válvulas (con límite físico ≥ 0)
  Qout_oil   = max(0, pidOil.y   * 0.01);
  Qout_water = max(0, pidWater.y * 0.01);
  Qout_gas   = max(0, pidGas.y   * 0.01);

end SeparadorTrifasicoControlado;
