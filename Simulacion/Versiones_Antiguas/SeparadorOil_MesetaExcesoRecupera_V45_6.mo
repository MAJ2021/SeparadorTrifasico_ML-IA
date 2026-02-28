model SeparadorOil_MesetaExcesoRecupera_V45_6
  inner Modelica.Fluid.System system;

  parameter Real V_sep   = 17.0 "Volumen del separador m3";
  parameter Real Qin_oil_base = 300/86400 "Caudal base de petróleo m3/s";
  parameter Real Tdelay = 5;

  Real V_oil(start=0, min=0);
  Real Qin_oil, Qout_oil;
  Real valveOilOut;

  Modelica.Blocks.Continuous.PID pidOilOut(k=0.05, Ti=2000, Td=0.1);
  Modelica.Blocks.Continuous.FirstOrder delayOilOut(T=Tdelay);

  Real V_oil_pct, spOil_pct;
  Real spDynamic;

equation
  // Set point fijo en 54%
  spDynamic = 0.54*V_sep;

  // Balance dinámico sin término artificial
  der(V_oil) = Qin_oil - Qout_oil;

  // PID con retardo
  pidOilOut.u = (spDynamic/V_sep*100) - (V_oil/V_sep*100);
  delayOilOut.u = pidOilOut.y;
  valveOilOut = min(max(delayOilOut.y, 0), 1);

  // Entrada según fases
  if time < 1800 then
    // Meseta inicial
    Qin_oil = Qin_oil_base;
  elseif time >= 1800 and time < 3600 then
    // Perturbación exceso → sube a 90%
    Qin_oil = Qin_oil_base*2.5;
  elseif time >= 3600 and time < 5400 then
    // Perturbación vaciado → baja a 20%
    Qin_oil = Qin_oil_base*0.2;
  else
    // Recuperación y meseta en 54%
    Qin_oil = Qin_oil_base;
  end if;

  // Salida siempre controlada por PID
  Qout_oil = valveOilOut * Qin_oil_base;

  // Variables en porcentaje
  V_oil_pct = V_oil / V_sep * 100;
  spOil_pct = spDynamic / V_sep * 100;

end SeparadorOil_MesetaExcesoRecupera_V45_6;
