within ;
package AbsorberGeneratorTIL
  "NH3-H2O generator/absorber with TIL connectors: connect a TIL pump, condenser, throttling valve and evaporator"

  // =====================================================================
  //  MAIN COMPONENT
  // =====================================================================
  model AbsorberGenerator
    "Generator + absorber (with integrated solution valve) for connection to TIL components"
    extends AbsorberGeneratorTIL.Interfaces.PartialNH3H2O;
    import SI = Modelica.Units.SI;

    // ---------------- Generator ----------------
    parameter Boolean specifyGeneratorPressure = false
      "= true: P_gen is known and the generator temperature is calculated"
      annotation (Dialog(group="Generator"), choices(checkBox=true), Evaluate=true);
    parameter SI.Temperature T_gen = 273.15 + 90 "Generator temperature"
      annotation (Dialog(group="Generator", enable=not specifyGeneratorPressure));
    parameter SI.AbsolutePressure P_gen = 1.6e6 "Generator pressure"
      annotation (Dialog(group="Generator", enable=specifyGeneratorPressure));

    // ---------------- Absorber ----------------
    parameter Boolean specifyStrongConcentration = false
      "= true: strong-solution NH3 fraction is known and the absorber pressure is calculated"
      annotation (Dialog(group="Absorber"), choices(checkBox=true), Evaluate=true);
    parameter SI.Temperature T_abs = 273.15 + 32 "Absorber temperature"
      annotation (Dialog(group="Absorber"));
    parameter SI.AbsolutePressure P_abs = 400e3 "Absorber pressure"
      annotation (Dialog(group="Absorber", enable=not specifyStrongConcentration));
    parameter Real X_strong = 0.47 "Strong-solution NH3 mass fraction"
      annotation (Dialog(group="Absorber", enable=specifyStrongConcentration));

    // ---------------- Vapor connections ----------------
    parameter Boolean idealVaporPorts = false
      "= true: no pressure drop between generator/condenser and evaporator/absorber"
      annotation (Dialog(group="Vapor connections"), choices(checkBox=true), Evaluate=true);
    parameter SI.PressureDifference dp_vapor_nominal = 1e3
      "Vapor-line pressure drop at nominal flow"
      annotation (Dialog(group="Vapor connections", enable=not idealVaporPorts));
    parameter SI.MassFlowRate m_flow_vapor_nominal = 0.05
      "Nominal refrigerant flow"
      annotation (Dialog(group="Vapor connections", enable=not idealVaporPorts));

    // ---------------- Start values ----------------
    parameter SI.AbsolutePressure p_gen_start = 1.6e6 "Generator pressure"
      annotation (Dialog(tab="Initialization"));
    parameter SI.AbsolutePressure p_abs_start = 400e3 "Absorber pressure"
      annotation (Dialog(tab="Initialization"));
    parameter Real X3_start = 0.97 "Refrigerant vapor NH3 fraction"
      annotation (Dialog(tab="Initialization"));
    parameter Real X5_start = 0.47 "Strong-solution NH3 fraction"
      annotation (Dialog(tab="Initialization"));
    parameter Real X7_start = 0.38 "Weak-solution NH3 fraction"
      annotation (Dialog(tab="Initialization"));
    parameter SI.MassFlowRate m_r_start = 0.05 "Refrigerant flow"
      annotation (Dialog(tab="Initialization"));
    parameter SI.MassFlowRate m_ss_start = 0.33 "Strong-solution flow"
      annotation (Dialog(tab="Initialization"));

    // ---------------- Connectors ----------------
    TIL.Connectors.VLEFluidPort vaporOut(final vleFluidType=vleFluidType)
      "Refrigerant vapor to the condenser (state 3)"
      annotation (Placement(transformation(extent={{-110,50},{-90,70}})));
    TIL.Connectors.VLEFluidPort vaporIn(final vleFluidType=vleFluidType)
      "Refrigerant from the evaporator (state 2)"
      annotation (Placement(transformation(extent={{-110,-70},{-90,-50}})));
    TIL.Connectors.VLEFluidPort strongIn(final vleFluidType=vleFluidType)
      "Strong solution from the pump outlet (state 6)"
      annotation (Placement(transformation(extent={{90,50},{110,70}})));
    TIL.Connectors.VLEFluidPort strongOut(final vleFluidType=vleFluidType)
      "Strong solution to the pump inlet (state 5)"
      annotation (Placement(transformation(extent={{90,-70},{110,-50}})));
    Modelica.Blocks.Interfaces.RealOutput Q_flow_gen(unit="W") "Generator heat input"
      annotation (Placement(transformation(extent={{100,10},{120,30}})));
    Modelica.Blocks.Interfaces.RealOutput Q_flow_abs(unit="W") "Absorber heat rejection"
      annotation (Placement(transformation(extent={{100,-30},{120,-10}})));

    // ---------------- Sub-components ----------------
    AbsorberGeneratorTIL.Components.Generator generator(
      final vleFluidType=vleFluidType,
      final xiIsWater=xiIsWater,
      final specifyPressure=specifyGeneratorPressure,
      final T_gen=T_gen,
      final P_gen=P_gen,
      final idealVaporPort=idealVaporPorts,
      final dp_vapor_nominal=dp_vapor_nominal,
      final m_flow_vapor_nominal=m_flow_vapor_nominal,
      final p_start=p_gen_start,
      final X3_start=X3_start,
      final X7_start=X7_start,
      final m_r_start=m_r_start,
      final m_ss_start=m_ss_start)
      annotation (Placement(transformation(extent={{-20,20},{20,60}})));
    AbsorberGeneratorTIL.Components.Absorber absorber(
      final vleFluidType=vleFluidType,
      final xiIsWater=xiIsWater,
      final specifyConcentration=specifyStrongConcentration,
      final T_abs=T_abs,
      final P_abs=P_abs,
      final X_strong=X_strong,
      final idealVaporPort=idealVaporPorts,
      final dp_vapor_nominal=dp_vapor_nominal,
      final m_flow_vapor_nominal=m_flow_vapor_nominal,
      final p_start=p_abs_start,
      final X5_start=X5_start,
      final m_r_start=m_r_start,
      final m_ss_start=m_ss_start)
      annotation (Placement(transformation(extent={{-20,-60},{20,-20}})));

    // ---------------- Results ----------------
    SI.AbsolutePressure P_high = generator.p_gen
      "Generator pressure (result unless specifyGeneratorPressure)";
    SI.AbsolutePressure P_low = absorber.p_abs "Absorber pressure";
    SI.Temperature T_generator = generator.T_gen_actual "Generator temperature";
    SI.MassFlowRate m_refrigerant = generator.m_r "Refrigerant flow (result)";
    SI.MassFlowRate m_strong = generator.m_ss "Strong-solution flow (set by the pump)";
    SI.MassFlowRate m_weak = generator.m_ws "Weak-solution flow";
    Real circulationRatio = m_strong/max(m_refrigerant, 1e-8)
      "Strong-solution flow per unit refrigerant flow";
    Real X_refrigerant = generator.X3 "Refrigerant vapor NH3 mass fraction";
    Real X_strongSolution = absorber.X5 "Strong-solution NH3 mass fraction";
    Real X_weakSolution = generator.X7 "Weak-solution NH3 mass fraction";

  equation
    connect(strongIn, generator.strongIn)
      annotation (Line(points={{100,60},{60,60},{60,48},{20,48}}, color={120,60,160}, thickness=0.5));
    connect(generator.vaporOut, vaporOut)
      annotation (Line(points={{-20,48},{-60,48},{-60,60},{-100,60}}, color={200,40,40}, thickness=0.5));
    connect(generator.weakOut, absorber.weakIn)
      annotation (Line(points={{0,20},{0,-20}}, color={120,60,160}, thickness=0.5));
    connect(vaporIn, absorber.vaporIn)
      annotation (Line(points={{-100,-60},{-60,-60},{-60,-44},{-20,-44}}, color={0,90,200}, thickness=0.5));
    connect(absorber.strongOut, strongOut)
      annotation (Line(points={{20,-50},{60,-50},{60,-60},{100,-60}}, color={120,60,160}, thickness=0.5));
    connect(generator.Q_flow_gen, Q_flow_gen)
      annotation (Line(points={{22,34},{80,34},{80,20},{110,20}}, color={0,0,127}));
    connect(absorber.Q_flow_abs, Q_flow_abs)
      annotation (Line(points={{22,-36},{80,-36},{80,-20},{110,-20}}, color={0,0,127}));

    annotation (
      Icon(coordinateSystem(preserveAspectRatio=false), graphics={
          Rectangle(extent={{-100,100},{100,-100}}, lineColor={95,95,95},
            fillColor={250,250,250}, fillPattern=FillPattern.Solid, radius=6),
          // generator
          Rectangle(extent={{-60,90},{60,30}}, lineColor={170,40,40},
            fillColor={255,200,190}, fillPattern=FillPattern.Solid),
          Rectangle(extent={{-58,50},{58,32}}, pattern=LinePattern.None,
            fillColor={240,150,130}, fillPattern=FillPattern.Solid),
          Text(extent={{-56,84},{56,56}}, textColor={130,20,20}, textString="Generator"),
          // absorber
          Rectangle(extent={{-60,-30},{60,-90}}, lineColor={30,80,160},
            fillColor={190,215,255}, fillPattern=FillPattern.Solid),
          Rectangle(extent={{-58,-70},{58,-88}}, pattern=LinePattern.None,
            fillColor={140,180,240}, fillPattern=FillPattern.Solid),
          Text(extent={{-56,-36},{56,-64}}, textColor={20,50,130}, textString="Absorber"),
          // weak solution through the integrated solution valve
          Line(points={{-40,30},{-40,-30}}, color={120,60,160}, thickness=0.5),
          Polygon(points={{-50,10},{-30,10},{-40,0},{-50,10}}, lineColor={0,0,0},
            fillColor={255,255,255}, fillPattern=FillPattern.Solid),
          Polygon(points={{-50,-10},{-30,-10},{-40,0},{-50,-10}}, lineColor={0,0,0},
            fillColor={255,255,255}, fillPattern=FillPattern.Solid),
          // refrigerant ports (left)
          Line(points={{-100,60},{-60,60}}, color={200,40,40}, thickness=0.5),
          Line(points={{-100,-60},{-60,-60}}, color={0,90,200}, thickness=0.5),
          Text(extent={{-98,76},{-62,66}}, textColor={200,40,40}, textString="to condenser"),
          Text(extent={{-98,-66},{-62,-76}}, textColor={0,90,200}, textString="from evaporator"),
          // strong-solution ports (right, to the external pump)
          Line(points={{60,60},{100,60}}, color={120,60,160}, thickness=0.5),
          Line(points={{60,-60},{100,-60}}, color={120,60,160}, thickness=0.5),
          Text(extent={{62,76},{98,66}}, textColor={120,60,160}, textString="from pump"),
          Text(extent={{62,-66},{98,-76}}, textColor={120,60,160}, textString="to pump"),
          // heat outputs
          Text(extent={{64,28},{98,12}}, textColor={200,60,0}, textString="Q_gen"),
          Text(extent={{64,-12},{98,-28}}, textColor={0,90,200}, textString="Q_abs"),
          // state labels
          Ellipse(extent={{-86,44},{-74,56}}, lineColor={0,0,0}, fillColor={255,255,255},
            fillPattern=FillPattern.Solid),
          Text(extent={{-86,44},{-74,56}}, textColor={0,0,0}, textString="3"),
          Ellipse(extent={{-86,-56},{-74,-44}}, lineColor={0,0,0}, fillColor={255,255,255},
            fillPattern=FillPattern.Solid),
          Text(extent={{-86,-56},{-74,-44}}, textColor={0,0,0}, textString="2"),
          Ellipse(extent={{74,44},{86,56}}, lineColor={0,0,0}, fillColor={255,255,255},
            fillPattern=FillPattern.Solid),
          Text(extent={{74,44},{86,56}}, textColor={0,0,0}, textString="6"),
          Ellipse(extent={{74,-56},{86,-44}}, lineColor={0,0,0}, fillColor={255,255,255},
            fillPattern=FillPattern.Solid),
          Text(extent={{74,-56},{86,-44}}, textColor={0,0,0}, textString="5"),
          Ellipse(extent={{-28,14},{-16,26}}, lineColor={0,0,0}, fillColor={255,255,255},
            fillPattern=FillPattern.Solid),
          Text(extent={{-28,14},{-16,26}}, textColor={0,0,0}, textString="7"),
          Ellipse(extent={{-28,-26},{-16,-14}}, lineColor={0,0,0}, fillColor={255,255,255},
            fillPattern=FillPattern.Solid),
          Text(extent={{-28,-26},{-16,-14}}, textColor={0,0,0}, textString="8"),
          Text(extent={{-150,140},{150,104}}, textColor={0,0,255}, textString="%name")}),
      Diagram(coordinateSystem(preserveAspectRatio=false)),
      Documentation(info="<html>
<p>Generator and absorber of a single-effect NH3-H2O absorption cycle, steady state
(no fluid storage), with <b>TIL VLEFluid connectors</b>. The solution expansion
valve (7 &rarr; 8) is built in. The solution pump, condenser, refrigerant throttling
valve and evaporator are connected from outside, for example TIL components.</p>
<h4>Connections</h4>
<ul>
<li><b>vaporOut</b> (state 3) &rarr; condenser inlet</li>
<li><b>vaporIn</b> (state 2) &larr; evaporator outlet</li>
<li><b>strongOut</b> (state 5) &rarr; pump inlet</li>
<li><b>strongIn</b> (state 6) &larr; pump outlet</li>
</ul>
<p>Connect VLE-fluid components only: TIL.VLEFluidComponents (pump, valve, tubes,
pressure state elements) and the VLEFluid side of TIL.HeatExchangers. NH3-H2O is a VLE
fluid in TILMedia, so this applies to the solution loop as well. TIL.LiquidComponents use
TIL.Connectors.LiquidPort and TILMedia liquid types (water, glycols), a different property
model; they belong on the water side of the heat exchangers.</p>
<p>This component, like TIL's components, takes its fluid from
<code>inner TIL.SystemInformationManager sim</code>: set VLE fluid 1 (vleFluidType1) of sim to
TILMedia_WaterAmmonia_nc2. sim numbers its fluids (VLE fluid 1 has ID = 1), and connected
ports must carry identical fluid records, so the fluid must come from sim rather than from a
separate copy of the record. If sim is missing, Dymola inserts a default one with a
one-component refrigerant.</p>
<p><b>TIL 2024.1 VLE components and NH3-H2O.</b> TIL's VLE components compute properties with
TILMedia's single-composition objects (TILMedia.VLEFluid_ph and similar). These accept pure
fluids and fixed-composition blends (nc = 1) and stop with \"This TILMedia VLEFluid interface
cannot handle variable concentrations\" for NH3-H2O with nc = 2. Such a component works here
only after its property objects are switched to TILMedia's mixture-capable versions
(TILMedia.Internals.VLEFluidConfigurations.FullyMixtureCompatible).</p>
<h4>Who sets what</h4>
<table border=\"1\" cellpadding=\"3\">
<tr><th>Quantity</th><th>Set by</th></tr>
<tr><td>Strong-solution flow</td><td>pump (known)</td></tr>
<tr><td>Pump pressure rise and outlet state</td><td>pump (result: it delivers whatever the generator pressure is)</td></tr>
<tr><td>Generator pressure P_gen</td><td>result: generator equilibrium at T_gen + refrigerant valve flow law</td></tr>
<tr><td>Refrigerant flow</td><td>result: ammonia balance of the generator</td></tr>
<tr><td>Absorber pressure P_abs</td><td>known (stands in for the system charge)</td></tr>
<tr><td>Weak-solution flow</td><td>result: generator mass balance</td></tr>
</table>
<p>Knowns of this component: T_gen, T_abs and P_abs. Use the check boxes to swap
T_gen for P_gen, or P_abs for the strong-solution concentration.</p>
<p>Without solution storage, a steady-state cycle has one free level (the total
ammonia charge). P_abs fixes it. Removing P_abs needs a dynamic absorber with
liquid inventory.</p>
<h4>Vapor connections</h4>
<p>By default the vapor ports have a small linear pressure drop
(dp_vapor_nominal at m_flow_vapor_nominal). This makes the ports flow-type, so
they connect cleanly to TIL heat exchangers that carry their own pressure state.
Set idealVaporPorts = true for no pressure drop.</p>
<h4>TIL enthalpy limiter (h_limit)</h4>
<p>TIL's VLEFluidPort carries h_limit, the minimum enthalpy a component accepts from
its neighbour. TIL's heat-exchanger cells use it to stay solvable during flow reversal
(Schulze, Gr&auml;ber, Tegethoff: \"A Limiter for Preventing Singularity in Simplified
Finite Volume Methods\").</p>
<ul>
<li>The generator and absorber have no finite-volume cells, so every port sends
h_limit = Interfaces.hLimitNone (-1e10 J/kg, meaning no limit).</li>
<li>Every outflow respects the limit sent by the connected component:
h_outflow = max(own enthalpy, inStream(h_limit)). The energy balances use these
outflow enthalpies.</li>
</ul>
<p>At normal operating points the limit lies far below the actual enthalpy, so the
results are the same as without the limiter.</p>
<h4>Dynamic TIL components</h4>
<p>This component stores no mass. TIL heat exchangers are finite-volume models that
take their pressure from a TIL pressure state element, one per pressure level: put one
between vaporOut and the condenser and one between the evaporator and vaporIn. Keep
idealVaporPorts = false. The small vapor-line resistance makes both vapor ports
flow-type, like a compressor or valve port, so the pressure state elements set the
condenser and evaporator pressures. With idealVaporPorts = true the absorber would fix
the evaporator pressure itself and clash with the element.</p>
<p>The absorber stays the pressure reference of the solution loop (like a TIL
boundary). absorber.massImbalance and absorber.ammoniaImbalance show the mismatch
during transients; both are zero at steady state.</p>
</html>"));
  end AbsorberGenerator;

  // =====================================================================
  //  Components
  // =====================================================================
  package Components "Generator and absorber, usable separately"

    model Generator "Generator with integrated solution expansion valve"
      extends AbsorberGeneratorTIL.Interfaces.PartialNH3H2O;
      import SI = Modelica.Units.SI;
      import AbsorberGeneratorTIL.Functions.xiOf;
      import AbsorberGeneratorTIL.Functions.XOf;

      // ---------------- Known quantity ----------------
      parameter Boolean specifyPressure = false
        "= true: P_gen is known and T_gen is calculated"
        annotation (Dialog(group="Known quantity"), choices(checkBox=true), Evaluate=true);
      parameter SI.Temperature T_gen = 273.15 + 90
        "Generator temperature (used if specifyPressure = false)"
        annotation (Dialog(group="Known quantity", enable=not specifyPressure));
      parameter SI.AbsolutePressure P_gen = 1.6e6
        "Generator pressure (used if specifyPressure = true)"
        annotation (Dialog(group="Known quantity", enable=specifyPressure));

      // ---------------- Vapor connection ----------------
      parameter Boolean idealVaporPort = false
        "= true: vaporOut.p equals the generator pressure (no vapor-line pressure drop)"
        annotation (Dialog(group="Vapor connection"), choices(checkBox=true), Evaluate=true);
      parameter SI.PressureDifference dp_vapor_nominal = 1e3
        "Vapor-line pressure drop at nominal flow"
        annotation (Dialog(group="Vapor connection", enable=not idealVaporPort));
      parameter SI.MassFlowRate m_flow_vapor_nominal = 0.05
        "Nominal refrigerant vapor flow"
        annotation (Dialog(group="Vapor connection", enable=not idealVaporPort));

      // ---------------- Start values ----------------
      parameter SI.AbsolutePressure p_start = 1.6e6 "Generator pressure"
        annotation (Dialog(tab="Initialization"));
      parameter Real X3_start = 0.97 "Vapor NH3 mass fraction"
        annotation (Dialog(tab="Initialization"));
      parameter Real X7_start = 0.38 "Weak-solution NH3 mass fraction"
        annotation (Dialog(tab="Initialization"));
      parameter SI.MassFlowRate m_r_start = 0.05 "Refrigerant flow"
        annotation (Dialog(tab="Initialization"));
      parameter SI.MassFlowRate m_ss_start = 0.33 "Strong-solution flow"
        annotation (Dialog(tab="Initialization"));

      // ---------------- Connectors ----------------
      TIL.Connectors.VLEFluidPort strongIn(final vleFluidType=vleFluidType, p(start=p_start), m_flow(start=m_ss_start))
        "Strong solution from the pump (state 6)"
        annotation (Placement(transformation(extent={{90,30},{110,50}})));
      TIL.Connectors.VLEFluidPort vaporOut(final vleFluidType=vleFluidType, p(start=p_start), m_flow(start=-m_r_start))
        "Refrigerant vapor to the condenser (state 3)"
        annotation (Placement(transformation(extent={{-110,30},{-90,50}})));
      TIL.Connectors.VLEFluidPort weakOut(final vleFluidType=vleFluidType, m_flow(start=-(m_ss_start - m_r_start)))
        "Weak solution after the solution valve, to the absorber (state 8)"
        annotation (Placement(transformation(extent={{-10,-110},{10,-90}})));
      Modelica.Blocks.Interfaces.RealOutput Q_flow_gen(unit="W") "Generator heat input"
        annotation (Placement(transformation(extent={{100,-40},{120,-20}})));

      // ---------------- Variables ----------------
      SI.AbsolutePressure p_gen(start=p_start) "Generator pressure";
      SI.Temperature T_gen_actual(start=T_gen) "Generator temperature";
      Real X3(start=X3_start, min=0, max=1) "State 3: vapor NH3 mass fraction (dew point)";
      Real X7(start=X7_start, min=0, max=1)
        "State 7: weak-solution NH3 mass fraction (bubble point)";
      SI.SpecificEnthalpy h3 "State 3: saturated vapor enthalpy";
      SI.SpecificEnthalpy h7 "State 7: saturated liquid enthalpy";
      SI.SpecificEnthalpy h6 = inStream(strongIn.h_outflow) "State 6: enthalpy from the pump";
      Real xi6[vleFluidType.nc - 1] = inStream(strongIn.xi_outflow)
        "State 6: TILMedia composition from the pump";
      Real X6 = XOf(xi6, xiIsWater) "State 6: NH3 mass fraction from the pump";
      SI.MassFlowRate m_ss = strongIn.m_flow "Strong solution in (set by the pump)";
      SI.MassFlowRate m_r = -vaporOut.m_flow "Refrigerant vapor out";
      SI.MassFlowRate m_ws = -weakOut.m_flow "Weak solution out";
      SI.Temperature T8 "State 8: temperature after the solution valve";
      Real Qu8 "State 8: vapor quality after the solution valve";
    protected
      final parameter Real k_vapor(unit="kg/(s.Pa)") = m_flow_vapor_nominal/dp_vapor_nominal
        "Vapor-line flow conductance";

    equation
      // ---------------- Known quantity ----------------
      if specifyPressure then
        p_gen = P_gen;
      else
        T_gen_actual = T_gen;
      end if;

      // ---------------- Port pressures and flows ----------------
      strongIn.p = p_gen "The pump delivers into the generator pressure";
      if idealVaporPort then
        vaporOut.p = p_gen;
      else
        m_r = k_vapor*(p_gen - vaporOut.p);
      end if;
      strongIn.m_flow + vaporOut.m_flow + weakOut.m_flow = 0 "Mass balance";
      m_ss*X6 = m_r*X3 + m_ws*X7 "Ammonia balance";

      // ---------------- Phase equilibrium at (p_gen, T_gen) ----------------
      T_gen_actual = TILMedia.VLEFluidFunctions.dewTemperature_pxi(
        vleFluidType, p_gen, xiOf(X3, xiIsWater));
      T_gen_actual = TILMedia.VLEFluidFunctions.bubbleTemperature_pxi(
        vleFluidType, p_gen, xiOf(X7, xiIsWater));
      h3 = TILMedia.VLEFluidFunctions.dewSpecificEnthalpy_pxi(
        vleFluidType, p_gen, xiOf(X3, xiIsWater));
      h7 = TILMedia.VLEFluidFunctions.bubbleSpecificEnthalpy_pxi(
        vleFluidType, p_gen, xiOf(X7, xiIsWater));

      // ---------------- Energy balance ----------------
      Q_flow_gen = m_r*vaporOut.h_outflow + m_ws*weakOut.h_outflow - m_ss*h6;

      // ---------------- Outflowing streams ----------------
      // TIL limiter: never send less than the minimum enthalpy (h_limit) the
      // connected component accepts. Inactive at normal operating points.
      vaporOut.h_outflow = noEvent(max(h3, inStream(vaporOut.h_limit)));
      vaporOut.xi_outflow = xiOf(X3, xiIsWater);
      weakOut.h_outflow = noEvent(max(h7, inStream(weakOut.h_limit)))
        "Isenthalpic solution valve";
      weakOut.xi_outflow = xiOf(X7, xiIsWater);
      strongIn.h_outflow = noEvent(max(h7, inStream(strongIn.h_limit)))
        "Only used if the flow reverses";
      strongIn.xi_outflow = xiOf(X7, xiIsWater);

      // ---------------- TIL enthalpy limit sent to neighbours ----------------
      // No finite-volume cells here, so any incoming enthalpy is accepted.
      vaporOut.h_limit = AbsorberGeneratorTIL.Interfaces.hLimitNone;
      weakOut.h_limit = AbsorberGeneratorTIL.Interfaces.hLimitNone;
      strongIn.h_limit = AbsorberGeneratorTIL.Interfaces.hLimitNone;

      // ---------------- State after the solution valve ----------------
      T8 = TILMedia.VLEFluidFunctions.temperature_phxi(
        vleFluidType, weakOut.p, weakOut.h_outflow, xiOf(X7, xiIsWater));
      Qu8 = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(
        vleFluidType, weakOut.p, weakOut.h_outflow, xiOf(X7, xiIsWater));

      annotation (
        Icon(coordinateSystem(preserveAspectRatio=false), graphics={
            Rectangle(extent={{-80,70},{80,-50}}, lineColor={170,40,40},
              fillColor={255,200,190}, fillPattern=FillPattern.Solid, radius=6),
            Rectangle(extent={{-78,-10},{78,-48}}, pattern=LinePattern.None,
              fillColor={240,150,130}, fillPattern=FillPattern.Solid),
            Text(extent={{-76,56},{76,26}}, textColor={130,20,20}, textString="Generator"),
            Line(points={{-100,40},{-80,40}}, color={200,40,40}, thickness=0.5),
            Line(points={{80,40},{100,40}}, color={120,60,160}, thickness=0.5),
            Line(points={{0,-50},{0,-100}}, color={120,60,160}, thickness=0.5),
            Polygon(points={{-12,-63},{12,-63},{0,-75},{-12,-63}}, lineColor={0,0,0},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            Polygon(points={{-12,-87},{12,-87},{0,-75},{-12,-87}}, lineColor={0,0,0},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            Line(points={{100,-30},{82,-30}}, color={200,60,0}, thickness=0.5,
              arrow={Arrow.None,Arrow.Filled}, arrowSize=8),
            Ellipse(extent={{-96,52},{-84,64}}, lineColor={0,0,0}, fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Text(extent={{-96,52},{-84,64}}, textColor={0,0,0}, textString="3"),
            Ellipse(extent={{84,52},{96,64}}, lineColor={0,0,0}, fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Text(extent={{84,52},{96,64}}, textColor={0,0,0}, textString="6"),
            Ellipse(extent={{12,-62},{24,-50}}, lineColor={0,0,0}, fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Text(extent={{12,-62},{24,-50}}, textColor={0,0,0}, textString="7"),
            Ellipse(extent={{12,-100},{24,-88}}, lineColor={0,0,0}, fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Text(extent={{12,-100},{24,-88}}, textColor={0,0,0}, textString="8"),
            Text(extent={{-150,110},{150,76}}, textColor={0,0,255}, textString="%name")}),
        Documentation(info="<html>
<p>Generator of a single-effect NH3-H2O cycle with the solution expansion valve
built in, steady state. Strong solution from the pump enters at strongIn,
saturated vapor (dew point) leaves at vaporOut, and saturated weak solution
(bubble point) leaves through the valve at weakOut, at the downstream pressure.</p>
<p>The pump sets the strong-solution flow. The generator gives the pump its
pressure (strongIn.p), splits the flow with the mass and ammonia balances, and
finds its pressure from the bubble point of the weak solution at T_gen.</p>
</html>"));
    end Generator;

    model Absorber "Absorber: refrigerant + weak solution in, saturated strong solution out"
      extends AbsorberGeneratorTIL.Interfaces.PartialNH3H2O;
      import SI = Modelica.Units.SI;
      import AbsorberGeneratorTIL.Functions.xiOf;
      import AbsorberGeneratorTIL.Functions.XOf;

      // ---------------- Known quantities ----------------
      parameter Boolean specifyConcentration = false
        "= true: X_strong is known and the absorber pressure is calculated"
        annotation (Dialog(group="Known quantities"), choices(checkBox=true), Evaluate=true);
      parameter SI.Temperature T_abs = 273.15 + 32 "Absorber temperature"
        annotation (Dialog(group="Known quantities"));
      parameter SI.AbsolutePressure P_abs = 400e3 "Absorber pressure"
        annotation (Dialog(group="Known quantities", enable=not specifyConcentration));
      parameter Real X_strong = 0.47 "Strong-solution NH3 mass fraction"
        annotation (Dialog(group="Known quantities", enable=specifyConcentration));

      // ---------------- Vapor connection ----------------
      parameter Boolean idealVaporPort = false
        "= true: vaporIn.p equals the absorber pressure (no vapor-line pressure drop)"
        annotation (Dialog(group="Vapor connection"), choices(checkBox=true), Evaluate=true);
      parameter SI.PressureDifference dp_vapor_nominal = 1e3
        "Vapor-line pressure drop at nominal flow"
        annotation (Dialog(group="Vapor connection", enable=not idealVaporPort));
      parameter SI.MassFlowRate m_flow_vapor_nominal = 0.05
        "Nominal refrigerant flow"
        annotation (Dialog(group="Vapor connection", enable=not idealVaporPort));

      // ---------------- Start values ----------------
      parameter SI.AbsolutePressure p_start = 400e3 "Absorber pressure"
        annotation (Dialog(tab="Initialization"));
      parameter Real X5_start = 0.47 "Strong-solution NH3 mass fraction"
        annotation (Dialog(tab="Initialization"));
      parameter SI.MassFlowRate m_r_start = 0.05 "Refrigerant flow"
        annotation (Dialog(tab="Initialization"));
      parameter SI.MassFlowRate m_ss_start = 0.33 "Strong-solution flow"
        annotation (Dialog(tab="Initialization"));

      // ---------------- Connectors ----------------
      TIL.Connectors.VLEFluidPort vaporIn(final vleFluidType=vleFluidType, p(start=p_start), m_flow(start=m_r_start))
        "Refrigerant from the evaporator (state 2)"
        annotation (Placement(transformation(extent={{-110,-30},{-90,-10}})));
      TIL.Connectors.VLEFluidPort weakIn(final vleFluidType=vleFluidType, p(start=p_start), m_flow(start=m_ss_start - m_r_start))
        "Weak solution from the generator (state 8)"
        annotation (Placement(transformation(extent={{-10,90},{10,110}})));
      TIL.Connectors.VLEFluidPort strongOut(final vleFluidType=vleFluidType, p(start=p_start), m_flow(start=-m_ss_start))
        "Strong solution to the pump (state 5)"
        annotation (Placement(transformation(extent={{90,-60},{110,-40}})));
      Modelica.Blocks.Interfaces.RealOutput Q_flow_abs(unit="W") "Absorber heat rejection"
        annotation (Placement(transformation(extent={{100,10},{120,30}})));

      // ---------------- Variables ----------------
      SI.AbsolutePressure p_abs(start=p_start) "Absorber pressure";
      Real X5(start=X5_start, min=0, max=1)
        "State 5: strong-solution NH3 mass fraction (bubble point)";
      SI.SpecificEnthalpy h5 "State 5: saturated liquid enthalpy";
      SI.SpecificEnthalpy h2 = inStream(vaporIn.h_outflow) "State 2: refrigerant enthalpy";
      Real xi2[vleFluidType.nc - 1] = inStream(vaporIn.xi_outflow)
        "State 2: TILMedia composition";
      Real X2 = XOf(xi2, xiIsWater) "State 2: refrigerant NH3 mass fraction";
      SI.SpecificEnthalpy h8 = inStream(weakIn.h_outflow) "State 8: weak-solution enthalpy";
      Real xi8[vleFluidType.nc - 1] = inStream(weakIn.xi_outflow)
        "State 8: TILMedia composition";
      Real X8 = XOf(xi8, xiIsWater) "State 8: weak-solution NH3 mass fraction";
      SI.MassFlowRate m_r = vaporIn.m_flow "Refrigerant in";
      SI.MassFlowRate m_ws = weakIn.m_flow "Weak solution in";
      SI.MassFlowRate m_ss = -strongOut.m_flow "Strong solution out (set by the pump)";
      SI.MassFlowRate massImbalance = m_r + m_ws - m_ss
        "In minus out; zero at steady state";
      SI.MassFlowRate ammoniaImbalance = m_r*X2 + m_ws*X8 - m_ss*X5
        "Ammonia in minus out; zero at steady state";
    protected
      final parameter Real k_vapor(unit="kg/(s.Pa)") = m_flow_vapor_nominal/dp_vapor_nominal
        "Vapor-line flow conductance";

    equation
      // ---------------- Known quantities ----------------
      if specifyConcentration then
        X5 = X_strong;
      else
        p_abs = P_abs;
      end if;

      // ---------------- Port pressures and flows ----------------
      weakIn.p = p_abs;
      strongOut.p = p_abs "The pump draws from the absorber pressure";
      if idealVaporPort then
        vaporIn.p = p_abs;
      else
        m_r = k_vapor*(vaporIn.p - p_abs);
      end if;

      // ---------------- Saturated strong solution at (p_abs, T_abs) ----------------
      T_abs = TILMedia.VLEFluidFunctions.bubbleTemperature_pxi(
        vleFluidType, p_abs, xiOf(X5, xiIsWater));
      h5 = TILMedia.VLEFluidFunctions.bubbleSpecificEnthalpy_pxi(
        vleFluidType, p_abs, xiOf(X5, xiIsWater));

      // ---------------- Energy balance ----------------
      Q_flow_abs = m_r*h2 + m_ws*h8 - m_ss*strongOut.h_outflow;

      // ---------------- Outflowing streams ----------------
      // TIL limiter: never send less than the minimum enthalpy (h_limit) the
      // connected component accepts. Inactive at normal operating points.
      strongOut.h_outflow = noEvent(max(h5, inStream(strongOut.h_limit)));
      strongOut.xi_outflow = xiOf(X5, xiIsWater);
      vaporIn.h_outflow = noEvent(max(h5, inStream(vaporIn.h_limit)))
        "Only used if the flow reverses";
      vaporIn.xi_outflow = xiOf(X5, xiIsWater);
      weakIn.h_outflow = noEvent(max(h5, inStream(weakIn.h_limit)))
        "Only used if the flow reverses";
      weakIn.xi_outflow = xiOf(X5, xiIsWater);

      // ---------------- TIL enthalpy limit sent to neighbours ----------------
      // No finite-volume cells here, so any incoming enthalpy is accepted.
      strongOut.h_limit = AbsorberGeneratorTIL.Interfaces.hLimitNone;
      vaporIn.h_limit = AbsorberGeneratorTIL.Interfaces.hLimitNone;
      weakIn.h_limit = AbsorberGeneratorTIL.Interfaces.hLimitNone;

      annotation (
        Icon(coordinateSystem(preserveAspectRatio=false), graphics={
            Rectangle(extent={{-80,50},{80,-70}}, lineColor={30,80,160},
              fillColor={190,215,255}, fillPattern=FillPattern.Solid, radius=6),
            Rectangle(extent={{-78,-30},{78,-68}}, pattern=LinePattern.None,
              fillColor={140,180,240}, fillPattern=FillPattern.Solid),
            Text(extent={{-76,36},{76,6}}, textColor={20,50,130}, textString="Absorber"),
            Line(points={{0,100},{0,50}}, color={120,60,160}, thickness=0.5),
            Line(points={{-100,-20},{-80,-20}}, color={0,90,200}, thickness=0.5),
            Line(points={{80,-50},{100,-50}}, color={120,60,160}, thickness=0.5),
            Line(points={{82,20},{100,20}}, color={0,90,200}, thickness=0.5,
              arrow={Arrow.None,Arrow.Filled}, arrowSize=8),
            Ellipse(extent={{6,62},{18,74}}, lineColor={0,0,0}, fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Text(extent={{6,62},{18,74}}, textColor={0,0,0}, textString="8"),
            Ellipse(extent={{-96,-8},{-84,4}}, lineColor={0,0,0}, fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Text(extent={{-96,-8},{-84,4}}, textColor={0,0,0}, textString="2"),
            Ellipse(extent={{84,-38},{96,-26}}, lineColor={0,0,0}, fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Text(extent={{84,-38},{96,-26}}, textColor={0,0,0}, textString="5"),
            Text(extent={{-150,-76},{150,-110}}, textColor={0,0,255}, textString="%name")}),
        Documentation(info="<html>
<p>Absorber of a single-effect NH3-H2O cycle, steady state. Refrigerant enters at
vaporIn, weak solution at weakIn, and saturated strong solution (bubble point at
T_abs) leaves at strongOut toward the pump.</p>
<p>The absorber is the pressure reference of the low side: it fixes P_abs (or,
with specifyConcentration, the strong-solution concentration). Its mass and
ammonia balances are not imposed, because in a closed steady-state cycle they
repeat the generator balances. massImbalance and ammoniaImbalance report them;
both are zero at steady state.</p>
</html>"));
    end Absorber;
  end Components;

  // =====================================================================
  //  Sensors
  // =====================================================================
  package Sensors "Measuring points that stay in place when components are swapped"

    model StatePoint
      "State point: reads p, T, h, NH3 fraction, quality and flow at a connection (no pressure drop, no storage)"
      extends AbsorberGeneratorTIL.Interfaces.PartialNH3H2O;
      import SI = Modelica.Units.SI;
      import AbsorberGeneratorTIL.Functions.XOf;

      parameter Integer stateNumber = 0 "State number shown on the icon";

      TIL.Connectors.VLEFluidPort portA(final vleFluidType=vleFluidType)
        "Upstream side (design flow direction A to B)"
        annotation (Placement(transformation(extent={{-110,-10},{-90,10}})));
      TIL.Connectors.VLEFluidPort portB(final vleFluidType=vleFluidType)
        "Downstream side"
        annotation (Placement(transformation(extent={{90,-10},{110,10}})));

      SI.MassFlowRate m_flow = portA.m_flow "Mass flow rate from A to B";
      SI.AbsolutePressure p = portA.p "Pressure";
      SI.SpecificEnthalpy h = inStream(portA.h_outflow)
        "Specific enthalpy of the fluid arriving at portA";
      Real xi[vleFluidType.nc - 1] = inStream(portA.xi_outflow)
        "TILMedia composition of the fluid arriving at portA";
      Real X = XOf(xi, xiIsWater) "NH3 mass fraction";
      SI.Temperature T "Temperature";
      Real Qu "Vapor quality";

    equation
      // Transparent: no pressure drop, no storage, every stream passes through
      portA.m_flow + portB.m_flow = 0;
      portB.p = portA.p;
      portB.h_outflow = inStream(portA.h_outflow);
      portA.h_outflow = inStream(portB.h_outflow);
      portB.xi_outflow = inStream(portA.xi_outflow);
      portA.xi_outflow = inStream(portB.xi_outflow);
      // TIL enthalpy limit: no volume here, so pass the neighbours' limits through
      portA.h_limit = inStream(portB.h_limit);
      portB.h_limit = inStream(portA.h_limit);

      // Readings
      T = TILMedia.VLEFluidFunctions.temperature_phxi(vleFluidType, p, h, xi);
      Qu = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(vleFluidType, p, h, xi);

      annotation (
        Icon(coordinateSystem(preserveAspectRatio=true), graphics={
            Ellipse(extent={{-90,90},{90,-90}}, lineColor={0,0,0},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            Text(extent={{-80,70},{80,-70}}, textColor={0,0,0},
              textString="%stateNumber")}),
        Documentation(info="<html>
<p>Measuring point between two components. It has no pressure drop and stores
nothing, so inserting it changes no result. It reports the pressure, temperature,
specific enthalpy, NH3 mass fraction, vapor quality and mass flow of the fluid
flowing from portA to portB.</p>
<p>Results that read state points instead of component internals stay valid when a
component on either side is replaced, for example a stand-in by a TIL component.</p>
</html>"));
    end StatePoint;
  end Sensors;

  // =====================================================================
  //  Examples
  // =====================================================================
  package Examples "Test cycle"

    model TestCycle
      "Complete cycle: AbsorberGenerator with simple stand-ins for the TIL pump, condenser, valve and evaporator"
      import SI = Modelica.Units.SI;

      parameter Boolean xiIsWater = true "See PartialNH3H2O";

      // ---------------- Knowns ----------------
      parameter SI.Temperature T_gen = 273.15 + 90 "Generator temperature";
      parameter SI.Temperature T_abs = 273.15 + 32 "Absorber temperature";
      parameter SI.AbsolutePressure P_abs = 400e3 "Absorber pressure";
      parameter SI.MassFlowRate m_strong = 0.33
        "Strong-solution flow set by the pump (use m_dot_abs from AbsorptionCycle_001)";
      parameter Real eta_p = 0.62 "Pump efficiency";
      parameter SI.Temperature T_amb = 273.15 + 25 "Ambient temperature";
      parameter SI.Temperature T_C = 273.15 + 5 "Evaporator temperature";
      parameter SI.TemperatureDifference DT_cond = 4 "Condenser approach";
      parameter SI.TemperatureDifference DT_evap = 3 "Evaporator approach";

      // ---------------- Valve sizing at the EES design point ----------------
      parameter SI.MassFlowRate m_r_design = 0.05 "Design refrigerant flow";
      parameter SI.AbsolutePressure P_gen_design = 1.6e6 "Design generator pressure";
      parameter SI.Density rho_valve_design = 590 "Liquid density at the valve inlet (estimate)";
      parameter SI.Area A_valve = m_r_design/sqrt(2*rho_valve_design*(P_gen_design - P_abs))
        "Valve flow area that passes the design flow at the design pressure difference";

      // ---------------- TIL fluid definitions ----------------
      // Every component (the AbsorberGenerator, state points and stand-ins, and any
      // TIL component) takes its fluid from VLE fluid 1 of sim, so all ports carry the
      // identical NH3-H2O record.
      inner TIL.SystemInformationManager sim(
        redeclare TILMedia.VLEFluidTypes.TILMedia_WaterAmmonia_nc2 vleFluidType1)
        "TIL fluid definitions: VLE fluid 1 = NH3-H2O for every component"
        annotation (Placement(transformation(extent={{-104,38},{-86,56}})));

      // ---------------- Components ----------------
      AbsorberGeneratorTIL.AbsorberGenerator absorberGenerator(
        xiIsWater=xiIsWater,
        T_gen=T_gen,
        T_abs=T_abs,
        P_abs=P_abs,
        m_ss_start=m_strong)
        annotation (Placement(transformation(extent={{20,-40},{100,40}})));
      AbsorberGeneratorTIL.Examples.StandIns.Pump pump(
        xiIsWater=xiIsWater,
        m_flow_set=m_strong,
        eta=eta_p)
        annotation (Placement(transformation(extent={{-20,-20},{20,20}},
              rotation=90, origin={140,0})));
      AbsorberGeneratorTIL.Examples.StandIns.Condenser condenser(
        xiIsWater=xiIsWater,
        T_out=T_amb + DT_cond)
        annotation (Placement(transformation(extent={{-10,4},{-50,44}})));
      AbsorberGeneratorTIL.Examples.StandIns.OrificeValve valve(
        xiIsWater=xiIsWater,
        A=A_valve)
        annotation (Placement(transformation(extent={{-20,-20},{20,20}},
              rotation=270, origin={-80,0})));
      AbsorberGeneratorTIL.Examples.StandIns.Evaporator evaporator(
        xiIsWater=xiIsWater,
        T_out=T_C - DT_evap)
        annotation (Placement(transformation(extent={{-50,-44},{-10,-4}})));

      // ---------------- State points ----------------
      // Results read these instead of the stand-ins, so they stay valid when a
      // stand-in is deleted and a TIL component is connected in its place.
      AbsorberGeneratorTIL.Sensors.StatePoint statePoint1(
        xiIsWater=xiIsWater,
        stateNumber=1) "Valve outlet / evaporator inlet"
        annotation (Placement(transformation(extent={{-70,-29},{-60,-19}})));
      AbsorberGeneratorTIL.Sensors.StatePoint statePoint2(
        xiIsWater=xiIsWater,
        stateNumber=2) "Evaporator outlet / absorber inlet"
        annotation (Placement(transformation(extent={{0,-29},{10,-19}})));
      AbsorberGeneratorTIL.Sensors.StatePoint statePoint4(
        xiIsWater=xiIsWater,
        stateNumber=4) "Condenser outlet / valve inlet"
        annotation (Placement(transformation(extent={{-60,19},{-70,29}})));
      AbsorberGeneratorTIL.Sensors.StatePoint statePoint6(
        xiIsWater=xiIsWater,
        stateNumber=6) "Pump outlet / generator inlet"
        annotation (Placement(transformation(extent={{125,19},{115,29}})));

      // ---------------- State table (EES numbering) ----------------
      SI.Temperature T[8] "State temperatures";
      SI.AbsolutePressure P[8] "State pressures";
      SI.SpecificEnthalpy h[8] "State specific enthalpies";
      Real X[8] "State NH3 mass fractions";

      // ---------------- Results ----------------
      // Only the AbsorberGenerator and the state points are read here, never the
      // stand-ins. Condenser and evaporator duties use the outlet flow, so they are
      // exact at steady state.
      Real P_gen_kPa(unit="kPa") = absorberGenerator.P_high/1e3 "Generator pressure (result)";
      SI.MassFlowRate m_refrigerant = absorberGenerator.m_refrigerant "Refrigerant flow (result)";
      Real Q_gen_kW(unit="kW") = absorberGenerator.Q_flow_gen/1e3 "Generator heat input";
      Real Q_evap_kW(unit="kW") = statePoint2.m_flow*(h[2] - h[1])/1e3 "Cooling capacity";
      Real Q_cond_kW(unit="kW") = statePoint4.m_flow*(h[3] - h[4])/1e3 "Condenser heat rejection";
      Real Q_abs_kW(unit="kW") = absorberGenerator.Q_flow_abs/1e3 "Absorber heat rejection";
      Real W_pump_kW(unit="kW") = statePoint6.m_flow*(h[6] - h[5])/1e3 "Pump power";
      Real COP = Q_evap_kW/Q_gen_kW "Coefficient of performance";
      Real balance_W(unit="W") = 1e3*(Q_gen_kW + Q_evap_kW + W_pump_kW - Q_cond_kW - Q_abs_kW)
        "Energy balance residual (zero at steady state)";

      // ---------------- Displays (filled in after simulation) ----------------
      Modelica.Blocks.Interaction.Show.RealValue dispPgen(use_numberPort=false,
        number=P_gen_kPa, significantDigits=4)
        annotation (Placement(transformation(extent={{180,55},{240,85}})));
      Modelica.Blocks.Interaction.Show.RealValue dispMr(use_numberPort=false,
        number=m_refrigerant, significantDigits=3)
        annotation (Placement(transformation(extent={{180,35},{240,65}})));
      Modelica.Blocks.Interaction.Show.RealValue dispQgen(use_numberPort=false,
        number=Q_gen_kW, significantDigits=3)
        annotation (Placement(transformation(extent={{180,15},{240,45}})));
      Modelica.Blocks.Interaction.Show.RealValue dispQevap(use_numberPort=false,
        number=Q_evap_kW, significantDigits=3)
        annotation (Placement(transformation(extent={{180,-5},{240,25}})));
      Modelica.Blocks.Interaction.Show.RealValue dispQcond(use_numberPort=false,
        number=Q_cond_kW, significantDigits=3)
        annotation (Placement(transformation(extent={{180,-25},{240,5}})));
      Modelica.Blocks.Interaction.Show.RealValue dispQabs(use_numberPort=false,
        number=Q_abs_kW, significantDigits=3)
        annotation (Placement(transformation(extent={{180,-45},{240,-15}})));
      Modelica.Blocks.Interaction.Show.RealValue dispWpump(use_numberPort=false,
        number=W_pump_kW, significantDigits=3)
        annotation (Placement(transformation(extent={{180,-65},{240,-35}})));
      Modelica.Blocks.Interaction.Show.RealValue dispCOP(use_numberPort=false,
        number=COP, significantDigits=3)
        annotation (Placement(transformation(extent={{180,-85},{240,-55}})));

    equation
      // ---------------- Refrigerant loop ----------------
      connect(absorberGenerator.vaporOut, condenser.portA)
        annotation (Line(points={{20,24},{-10,24}}, color={200,40,40}, thickness=0.5));
      connect(condenser.portB, statePoint4.portA)
        annotation (Line(points={{-50,24},{-60,24}}, color={200,40,40}, thickness=0.5));
      connect(statePoint4.portB, valve.portA)
        annotation (Line(points={{-70,24},{-80,24},{-80,20}}, color={200,40,40}, thickness=0.5));
      connect(valve.portB, statePoint1.portA)
        annotation (Line(points={{-80,-20},{-80,-24},{-70,-24}}, color={0,90,200}, thickness=0.5));
      connect(statePoint1.portB, evaporator.portA)
        annotation (Line(points={{-60,-24},{-50,-24}}, color={0,90,200}, thickness=0.5));
      connect(evaporator.portB, statePoint2.portA)
        annotation (Line(points={{-10,-24},{0,-24}}, color={0,90,200}, thickness=0.5));
      connect(statePoint2.portB, absorberGenerator.vaporIn)
        annotation (Line(points={{10,-24},{20,-24}}, color={0,90,200}, thickness=0.5));

      // ---------------- Solution loop (pump) ----------------
      connect(absorberGenerator.strongOut, pump.portA)
        annotation (Line(points={{100,-24},{140,-24},{140,-20}}, color={120,60,160}, thickness=0.5));
      connect(pump.portB, statePoint6.portA)
        annotation (Line(points={{140,20},{140,24},{125,24}}, color={120,60,160}, thickness=0.5));
      connect(statePoint6.portB, absorberGenerator.strongIn)
        annotation (Line(points={{115,24},{100,24}}, color={120,60,160}, thickness=0.5));

      // ---------------- State table ----------------
      // 1: valve outlet / evaporator inlet
      T[1] = statePoint1.T;
      P[1] = statePoint1.p;
      h[1] = statePoint1.h;
      X[1] = statePoint1.X;
      // 2: evaporator outlet / absorber inlet
      T[2] = statePoint2.T;
      P[2] = statePoint2.p;
      h[2] = statePoint2.h;
      X[2] = statePoint2.X;
      // 3: generator vapor
      T[3] = absorberGenerator.generator.T_gen_actual;
      P[3] = absorberGenerator.generator.p_gen;
      h[3] = absorberGenerator.generator.h3;
      X[3] = absorberGenerator.generator.X3;
      // 4: condenser outlet / valve inlet
      T[4] = statePoint4.T;
      P[4] = statePoint4.p;
      h[4] = statePoint4.h;
      X[4] = statePoint4.X;
      // 5: absorber outlet / pump inlet
      T[5] = absorberGenerator.absorber.T_abs;
      P[5] = absorberGenerator.absorber.p_abs;
      h[5] = absorberGenerator.absorber.h5;
      X[5] = absorberGenerator.absorber.X5;
      // 6: pump outlet / generator inlet
      T[6] = statePoint6.T;
      P[6] = statePoint6.p;
      h[6] = statePoint6.h;
      X[6] = statePoint6.X;
      // 7: generator liquid outlet
      T[7] = absorberGenerator.generator.T_gen_actual;
      P[7] = absorberGenerator.generator.p_gen;
      h[7] = absorberGenerator.generator.h7;
      X[7] = absorberGenerator.generator.X7;
      // 8: after the solution valve / absorber inlet
      T[8] = absorberGenerator.generator.T8;
      P[8] = absorberGenerator.absorber.p_abs;
      h[8] = absorberGenerator.generator.h7;
      X[8] = absorberGenerator.generator.X7;

      annotation (
        experiment(StopTime=1),
        Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-110,-95},{255,100}}),
          graphics={
            // pressure zones
            Rectangle(extent={{-108,0},{165,82}}, pattern=LinePattern.None,
              fillColor={255,243,238}, fillPattern=FillPattern.Solid),
            Rectangle(extent={{-108,-90},{165,0}}, pattern=LinePattern.None,
              fillColor={236,244,255}, fillPattern=FillPattern.Solid),
            Line(points={{-108,0},{165,0}}, color={150,150,150}, pattern=LinePattern.Dash),
            Text(extent={{-106,70},{-30,78}}, textColor={170,40,40},
              horizontalAlignment=TextAlignment.Left, textString="HIGH PRESSURE (result)"),
            Text(extent={{-106,-78},{-30,-70}}, textColor={20,60,150},
              horizontalAlignment=TextAlignment.Left, textString="LOW PRESSURE (P_abs)"),
            Text(extent={{-106,86},{165,98}}, textColor={0,0,0},
              horizontalAlignment=TextAlignment.Left,
              textString="NH3-H2O absorption cycle: AbsorberGenerator + TIL-style components"),
            // heat flows
            Line(points={{-30,48},{-30,62}}, color={200,60,0}, thickness=0.5,
              arrow={Arrow.None,Arrow.Filled}, arrowSize=4),
            Text(extent={{-26,54},{0,62}}, textColor={200,60,0},
              horizontalAlignment=TextAlignment.Left, textString="Q_cond"),
            Line(points={{-30,-62},{-30,-48}}, color={0,90,200}, thickness=0.5,
              arrow={Arrow.None,Arrow.Filled}, arrowSize=4),
            Text(extent={{-26,-62},{0,-54}}, textColor={0,90,200},
              horizontalAlignment=TextAlignment.Left, textString="Q_evap"),
            // state labels 3 and 5 (1, 2, 4 and 6 are the state-point sensors;
            // 7 and 8 are inside the AbsorberGenerator icon)
            Ellipse(extent={{0,25},{10,35}}, lineColor={0,0,0},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            Text(extent={{0,25},{10,35}}, textColor={0,0,0}, textString="3"),
            Ellipse(extent={{115,-35},{125,-25}}, lineColor={0,0,0},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid),
            Text(extent={{115,-35},{125,-25}}, textColor={0,0,0}, textString="5"),
            // results panel
            Rectangle(extent={{170,-90},{250,98}}, lineColor={120,120,120},
              fillColor={255,255,255}, fillPattern=FillPattern.Solid, radius=3),
            Text(extent={{172,88},{248,96}}, textColor={0,0,0},
              textString="Results (after simulation)")}),
        Documentation(info="<html>
<p>Full cycle with the AbsorberGenerator and simple stand-ins for the pump, condenser,
throttling valve and evaporator. All ports are TIL VLEFluid connectors, so each
stand-in can be replaced with a TIL component.</p>
<p><b>Knowns:</b> T_gen, T_abs, P_abs (AbsorberGenerator), strong-solution flow and
efficiency (pump), flow area (valve), outlet temperatures (condenser, evaporator).
<b>Results:</b> generator pressure, refrigerant flow, all heat flows and the COP.</p>
<p>The results and the state table read only the AbsorberGenerator and the state points
1, 2, 4 and 6 (Sensors.StatePoint), never the stand-ins. Deleting a stand-in therefore
leaves every result equation intact: connect the replacement between the same two
points.</p>
<p>The valve area is sized so the EES design point (0.05 kg/s at 1600/400 kPa)
is reproduced when m_strong matches m_dot_abs from AbsorptionCycle_001.</p>
<h4>Swapping in TIL components</h4>
<ol>
<li>Duplicate this model first, so the stand-in version stays as a reference.</li>
<li>All components take their fluid from <code>sim</code>. This model already contains
<code>inner TIL.SystemInformationManager sim</code> with VLE fluid 1 (vleFluidType1) set
to TILMedia_WaterAmmonia_nc2, so the AbsorberGenerator, the state points, the stand-ins and
any dropped-in TIL component carry the same NH3-H2O record. In a new model, drag
TIL.SystemInformationManager in and set that field yourself. For the heat exchangers, also
set the secondary-side liquid or gas type in sim.</li>
<li>TIL 2024.1's VLE components use TILMedia's single-composition property objects and
reject NH3-H2O with nc = 2 (see the errors below). A TIL component needs a copy with
mixture-capable property objects before it can be connected here.</li>
<li>Use the VLE-fluid branch of TIL: TIL.VLEFluidComponents (pump, valve, pressure state
element) and the VLEFluid side of TIL.HeatExchangers. NH3-H2O is a VLE fluid in TILMedia,
so the solution loop belongs there too, even though it is liquid. TIL.LiquidComponents use
TIL.Connectors.LiquidPort and TILMedia liquid types; they do not connect to these ports
and belong on the water side of the heat exchangers.</li>
<li><b>Pump</b>, between absorberGenerator.strongOut and statePoint6: set it to impose the
flow (mass flow m_strong, or the matching volume flow or speed), not a pressure rise. The
AbsorberGenerator already fixes the pressure on both sides of the pump.</li>
<li><b>Valve</b>, between statePoint4 and statePoint1: orifice valve with effective flow
area A_valve.</li>
<li><b>Condenser</b>, between absorberGenerator.vaporOut and statePoint4, and
<b>evaporator</b>, between statePoint1 and statePoint2: TIL heat exchangers take their
pressure from a pressure state element, one per pressure level. Put one between vaporOut
and the condenser (start about 1600 kPa) and one between the evaporator and vaporIn
(start about 400 kPa). If the heat exchangers have a pressureStateID, match it to the
element on their side. Keep idealVaporPorts = false.</li>
<li>Raise StopTime. The stand-ins store nothing, so 1 s is enough for them; TIL heat
exchangers need time to settle. Steady state is reached when
absorberGenerator.absorber.massImbalance and ammoniaImbalance are zero.</li>
</ol>
<p>Swap the pump first. It needs no pressure state element, so it runs with the stand-in
heat exchangers. TIL.VLEFluidComponents.Pumps.SimplePump as shipped with TIL 2024.1 stops
with the variable-concentration error below; a mixture-capable copy is needed.</p>
<h4>Errors after a swap</h4>
<ul>
<li><b>\"Incompatible sizes ... sizes 1 and 0\"</b> for an xi or xi_outflow variable:
the TIL component uses a fluid with one component. sim is missing or its VLE fluid 1
is not TILMedia_WaterAmmonia_nc2.</li>
<li><b>\"This TILMedia VLEFluid interface cannot handle variable concentrations\"</b>
inside a TIL component: that component computes its properties with TILMedia's
single-composition objects (TILMedia.VLEFluid_ph and similar). No setting changes this; the
component needs a copy with TILMedia's mixture-capable objects
(TILMedia.Internals.VLEFluidConfigurations.FullyMixtureCompatible).</li>
<li><b>\"Parameters in connected connectors must be equal\"</b> for vleFluidType.ID: one
side carries its own copy of the fluid record instead of sim's. Leave vleFluidType at its
default (sim.vleFluidType1) in every component.</li>
<li><b>Too many equations / structurally singular</b> right after swapping the pump:
the pump is set to impose a pressure rise. Switch it to mass or volume flow.</li>
</ul>
</html>"));
    end TestCycle;

    package StandIns "Simple pump, condenser, valve and evaporator with TIL connectors (replace with TIL components)"

      partial model PartialTwoPort "Two-port with TIL connectors, no storage"
        extends AbsorberGeneratorTIL.Interfaces.PartialNH3H2O;
        parameter Modelica.Units.SI.AbsolutePressure pA_start = 1e6 "Inlet pressure"
          annotation (Dialog(tab="Initialization"));
        parameter Modelica.Units.SI.AbsolutePressure pB_start = 1e6 "Outlet pressure"
          annotation (Dialog(tab="Initialization"));
        TIL.Connectors.VLEFluidPort portA(final vleFluidType=vleFluidType, p(start=pA_start))
          "Inlet"
          annotation (Placement(transformation(extent={{-110,-10},{-90,10}})));
        TIL.Connectors.VLEFluidPort portB(final vleFluidType=vleFluidType, p(start=pB_start))
          "Outlet"
          annotation (Placement(transformation(extent={{90,-10},{110,10}})));
        Modelica.Units.SI.SpecificEnthalpy h_in = inStream(portA.h_outflow) "Inlet enthalpy";
        Real xi_in[vleFluidType.nc - 1] = inStream(portA.xi_outflow)
          "Inlet TILMedia composition";
        Real X_in = AbsorberGeneratorTIL.Functions.XOf(xi_in, xiIsWater)
          "Inlet NH3 mass fraction";
        Modelica.Units.SI.MassFlowRate m_flow = portA.m_flow "Mass flow rate";
      equation
        portA.m_flow + portB.m_flow = 0;
        portB.xi_outflow = xi_in;
        portA.h_outflow = inStream(portB.h_outflow);
        portA.xi_outflow = inStream(portB.xi_outflow);
        // TIL enthalpy limit: no volume here, so pass the neighbours' limits through
        portA.h_limit = inStream(portB.h_limit);
        portB.h_limit = inStream(portA.h_limit);
      end PartialTwoPort;

      model Pump "Pump with fixed mass flow (stand-in for the TIL pump)"
        extends PartialTwoPort(pA_start=400e3, pB_start=1.6e6);
        parameter Modelica.Units.SI.MassFlowRate m_flow_set = 0.33 "Mass flow rate";
        parameter Real eta = 0.62 "Pump efficiency";
        Modelica.Units.SI.Density rho_in "Inlet density (saturated liquid)";
        Modelica.Units.SI.Temperature T_out "Outlet temperature";
        Modelica.Blocks.Interfaces.RealOutput P_pump(unit="W") "Pump power"
          annotation (Placement(transformation(extent={{-10,-10},{10,10}},
                rotation=90, origin={0,110})));
      equation
        portA.m_flow = m_flow_set;
        rho_in = TILMedia.VLEFluidFunctions.bubbleDensity_pxi(vleFluidType, portA.p, xi_in);
        portB.h_outflow = h_in + (portB.p - portA.p)/(rho_in*eta);
        P_pump = m_flow*(portB.h_outflow - h_in);
        T_out = TILMedia.VLEFluidFunctions.temperature_phxi(
          vleFluidType, portB.p, portB.h_outflow, xi_in);
        annotation (Icon(coordinateSystem(preserveAspectRatio=false), graphics={
              Line(points={{-100,0},{-60,0}}, color={120,60,160}, thickness=0.5),
              Line(points={{60,0},{100,0}}, color={120,60,160}, thickness=0.5),
              Ellipse(extent={{-60,60},{60,-60}}, lineColor={0,0,0},
                fillColor={255,255,255}, fillPattern=FillPattern.Solid),
              Polygon(points={{-28,40},{52,0},{-28,-40},{-28,40}}, lineColor={0,0,0},
                fillColor={120,60,160}, fillPattern=FillPattern.Solid),
              Text(extent={{-150,-66},{150,-100}}, textColor={0,0,255}, textString="%name")}));
      end Pump;

      model Condenser "Condenser with fixed outlet temperature (stand-in for a TIL heat exchanger)"
        extends PartialTwoPort(pA_start=1.6e6, pB_start=1.6e6);
        parameter Modelica.Units.SI.Temperature T_out = 273.15 + 29 "Outlet temperature";
        Real Qu_out "Outlet vapor quality";
        Modelica.Blocks.Interfaces.RealOutput Q_flow(unit="W") "Heat rejected"
          annotation (Placement(transformation(extent={{-10,-10},{10,10}},
                rotation=90, origin={0,110})));
      equation
        portB.p = portA.p;
        portB.h_outflow = TILMedia.VLEFluidFunctions.specificEnthalpy_pTxi(
          vleFluidType, portA.p, T_out, xi_in);
        Qu_out = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(
          vleFluidType, portA.p, portB.h_outflow, xi_in);
        Q_flow = m_flow*(h_in - portB.h_outflow);
        annotation (Icon(coordinateSystem(preserveAspectRatio=false), graphics={
              Rectangle(extent={{-80,40},{80,-40}}, lineColor={170,40,40},
                fillColor={255,225,215}, fillPattern=FillPattern.Solid),
              Line(points={{-100,0},{-60,0},{-50,20},{-30,-20},{-10,20},{10,-20},
                {30,20},{50,-20},{60,0},{100,0}}, color={200,40,40}, thickness=0.5),
              Text(extent={{-80,-44},{80,-70}}, textColor={130,20,20}, textString="Condenser"),
              Text(extent={{-150,90},{150,56}}, textColor={0,0,255}, textString="%name")}));
      end Condenser;

      model OrificeValve "Orifice throttling valve (stand-in for a TIL valve)"
        extends PartialTwoPort(pA_start=1.6e6, pB_start=400e3);
        parameter Modelica.Units.SI.Area A = 1.3e-6 "Effective flow area";
        parameter Modelica.Units.SI.PressureDifference dp_small = 1e3
          "Smoothing range around zero pressure difference";
        Modelica.Units.SI.Density rho_in "Inlet density (saturated-liquid estimate)";
        Modelica.Units.SI.Temperature T_out "Outlet temperature";
        Real Qu_out "Outlet vapor quality";
      equation
        rho_in = TILMedia.VLEFluidFunctions.bubbleDensity_pxi(vleFluidType, portA.p, xi_in);
        portA.m_flow = A*sqrt(2*rho_in)*Modelica.Fluid.Utilities.regRoot(portA.p - portB.p, dp_small);
        portB.h_outflow = h_in;
        T_out = TILMedia.VLEFluidFunctions.temperature_phxi(vleFluidType, portB.p, h_in, xi_in);
        Qu_out = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(vleFluidType, portB.p, h_in, xi_in);
        annotation (Icon(coordinateSystem(preserveAspectRatio=false), graphics={
              Polygon(points={{-80,40},{-80,-40},{0,0},{-80,40}}, lineColor={0,0,0},
                fillColor={255,255,255}, fillPattern=FillPattern.Solid),
              Polygon(points={{80,40},{80,-40},{0,0},{80,40}}, lineColor={0,0,0},
                fillColor={255,255,255}, fillPattern=FillPattern.Solid),
              Line(points={{-100,0},{-80,0}}, color={200,40,40}, thickness=0.5),
              Line(points={{80,0},{100,0}}, color={0,90,200}, thickness=0.5),
              Text(extent={{-150,-50},{150,-90}}, textColor={0,0,255}, textString="%name")}));
      end OrificeValve;

      model Evaporator "Evaporator with fixed outlet temperature (stand-in for a TIL heat exchanger)"
        extends PartialTwoPort(pA_start=400e3, pB_start=400e3);
        parameter Modelica.Units.SI.Temperature T_out = 273.15 + 2 "Outlet temperature";
        Real Qu_out "Outlet vapor quality";
        Modelica.Blocks.Interfaces.RealOutput Q_flow(unit="W") "Cooling capacity"
          annotation (Placement(transformation(extent={{-10,-10},{10,10}},
                rotation=270, origin={0,-110})));
      equation
        portB.p = portA.p;
        portB.h_outflow = TILMedia.VLEFluidFunctions.specificEnthalpy_pTxi(
          vleFluidType, portA.p, T_out, xi_in);
        Qu_out = TILMedia.VLEFluidFunctions.steamMassFraction_phxi(
          vleFluidType, portA.p, portB.h_outflow, xi_in);
        Q_flow = m_flow*(portB.h_outflow - h_in);
        annotation (Icon(coordinateSystem(preserveAspectRatio=false), graphics={
              Rectangle(extent={{-80,40},{80,-40}}, lineColor={30,80,160},
                fillColor={215,235,255}, fillPattern=FillPattern.Solid),
              Line(points={{-100,0},{-60,0},{-50,20},{-30,-20},{-10,20},{10,-20},
                {30,20},{50,-20},{60,0},{100,0}}, color={0,90,200}, thickness=0.5),
              Text(extent={{-80,70},{80,44}}, textColor={20,50,130}, textString="Evaporator"),
              Text(extent={{-150,-56},{150,-90}}, textColor={0,0,255}, textString="%name")}));
      end Evaporator;
    end StandIns;
  end Examples;

  // =====================================================================
  //  Interfaces and functions
  // =====================================================================
  package Interfaces "Partial models and constants"
    constant Modelica.Units.SI.SpecificEnthalpy hLimitNone = -1e10
      "h_limit value meaning no lower enthalpy limit (any incoming enthalpy is accepted)";

    partial model PartialNH3H2O "Fluid definition shared by all components"
      // The fluid comes from sim, like in TIL's own components. sim gives each of its
      // fluids an ID (VLE fluid 1 has ID = 1), and connected ports must carry identical
      // records, so a separate copy of the NH3-H2O record (ID = 0) would not connect to
      // TIL components.
      outer TIL.SystemInformationManager sim "TIL system information manager (fluid definitions)";
      replaceable parameter TILMedia.VLEFluidTypes.BaseVLEFluid vleFluidType = sim.vleFluidType1
        constrainedby TILMedia.VLEFluidTypes.BaseVLEFluid
        "NH3-H2O working fluid (default: VLE fluid 1 of sim, which must be TILMedia_WaterAmmonia_nc2)"
        annotation (choicesAllMatching=true, Dialog(tab="Fluid"));
      parameter Boolean xiIsWater = true
        "= true: TILMedia xi[1] is the water mass fraction (xi = 1 - X_NH3)"
        annotation (Dialog(tab="Fluid"), choices(checkBox=true));
    equation
      assert(vleFluidType.nc == 2,
        "AbsorberGeneratorTIL needs a two-component fluid: set VLE fluid 1 (vleFluidType1) of sim to TILMedia_WaterAmmonia_nc2");
    end PartialNH3H2O;
  end Interfaces;

  package Functions "Composition helpers"
    function xiOf "TILMedia composition vector from NH3 mass fraction"
      input Real X "NH3 mass fraction";
      input Boolean xiIsWater = true "true: xi[1] is the water mass fraction";
      output Real xi[1] "TILMedia composition vector";
    algorithm
      xi := {if xiIsWater then 1 - X else X};
      annotation (Inline=true);
    end xiOf;

    function XOf "NH3 mass fraction from TILMedia composition vector"
      input Real xi[:] "TILMedia composition vector";
      input Boolean xiIsWater = true "true: xi[1] is the water mass fraction";
      output Real X "NH3 mass fraction";
    algorithm
      X := if xiIsWater then 1 - xi[1] else xi[1];
      annotation (Inline=true);
    end XOf;
  end Functions;

  annotation (uses(TILMedia(version="2024.1"), Modelica(version="4.0.0")),
    Documentation(info="<html>
<p>Steady-state NH3-H2O generator/absorber with TIL VLEFluid connectors
(TIL.Connectors.VLEFluidPort).</p>
<ul>
<li><b>AbsorberGenerator</b>: the combined component (main item).</li>
<li><b>Components.Generator</b>, <b>Components.Absorber</b>: the two halves, usable separately.</li>
<li><b>Sensors.StatePoint</b>: transparent measuring point (p, T, h, NH3 fraction, quality, flow).</li>
<li><b>Examples.TestCycle</b>: complete cycle with stand-ins for the TIL pump, condenser, valve and
evaporator; its results read state points, so the stand-ins can be swapped for TIL components.</li>
</ul>
</html>"));
end AbsorberGeneratorTIL;
