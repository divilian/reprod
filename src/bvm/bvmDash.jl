
import HTTP
using Dash
using DataFrames, DataFramesMeta, CSV

include("bvm.jl")

using .bvm

external_stylesheets = [
    "https://codepen.io/chriddyp/pen/bWLwgP.css",
    "http://stephendavies.org/dash.css"]

app = dash("Binary Voter Model", external_stylesheets=external_stylesheets)

function inputs(button_name, button_id)
    html_div(className="inputs-div") do
        html_div(id="outer-div") do
            html_h3("Erdos-Renyi graph parameters"),
            html_div(id="er-div", className="widgets") do
                html_span("N"),
                dcc_input(
                    id="n",
                    type="number",
                    min=10, max=50, step=1,
                    value=10,
                    style=Dict("width" => "80px")
                ),
                html_span("p"),
                dcc_input(
                    id="p",
                    type="number",
                    value=.2,
                    min=0.1, max=1.0, step=.05,
                    style=Dict("width" => "80px")
                )
            end
        end,
        html_div(id="variations-div") do
            html_h3("Variations"),
            html_div(id="influences-div", className="widgets") do
                html_span("node"),
                dcc_dropdown(
                    id="influencer",
                    options=[Dict("label" => "influences",
                                "value" => "nodeInfluencer"),
                             Dict("label" => "is influenced by",
                                "value" => "nodeInfluencee")],
                    style=Dict("width" => "150px", "display" => "inline-block"),
                    value="nodeInfluencer"
                ),
                html_span("neighbor")
            end,
            html_div(id="replacement-div", className="widgets") do
                html_span("choose nodes"),
                dcc_dropdown(
                    id="replacement",
                    options=[Dict("label" => "with",
                                "value" => "replacement"),
                             Dict("label" => "without",
                                "value" => "noReplacement")],
                    style=Dict("width" => "120px", "display" => "inline-block"),
                    value="noReplacement",
                ),
                html_span("replacement")
            end
        end,
        html_button(button_name, id=button_id)
    end
end


app.layout = html_div(id="top") do
    html_h1("Binary Voter Model"),

    dcc_tabs(value="single-run-tab") do
        dcc_tab(label="Single run",value="single-run-tab") do
            inputs("Run single sim", "run-sim"),
            html_div(id="single-outputs-div") do
                dcc_graph(
                    id="time-series-plot",
                ),
                html_p("", id="status-msg")
            end
        end,
        dcc_tab(label="Multiple runs",value="multi-run-tab") do
            inputs("Run suite", "run-suite"),
            html_div(id="multi-outputs-div") do
                dcc_graph(
                    id="time-series-plots",
                ),
                html_p("", id="status-msg2")
            end
        end
    end
end


callback!(app, callid"run-sim.n_clicks, n.value, p.value, influencer.value, replacement.value => status-msg.children, time-series-plot.figure") do n_clicks, n, p, influencer, replacement

    if isnothing(n)
        return
    end
    msg, results = bvm.run_sim(n, p, influencer == "nodeInfluencer",
        replacement == "replacement"; verbose=false, make_plots=false,
        make_anim=false)
    return (msg,
        Dict(
            "data" => [
                Dict("x" => results.iter,
                     "y" => results.frac_red,
                     "name" => "Fraction with red opinion",
                     "mode" => "lines",
                     "type" => "scatter",
                     "marker" => Dict("color"=>"darkred")
                )
            ],
            "layout" => Dict("title"=>"Fraction with red opinion",
                             "xaxis"=>Dict("title"=>"Iteration #"),
                             "yaxis" => Dict("range"=>[0.0,1.0]))
        )
    )
end

callback!(app, callid"run-suite.n_clicks, n.value, p.value, influencer.value, replacement.value => status-msg2.children, time-series-plots.figure") do n_clicks, n, p, influencer, replacement
    if isnothing(n)
        return
    end
    msg, results = bvm.run_sims(10, n, p, influencer == "nodeInfluencer",
        replacement == "replacement"; verbose=false, make_plots=false)
    return (msg,
        Dict(
            "data" => [
                Dict("x" => @where(results,:trial.==t).iter,
                     "y" => @where(results,:trial.==t).frac_red,
                     "mode" => "lines",
                     "type" => "scatter",
                     "marker" => Dict("color"=>"darkred")
                ) for t in unique(results.trial)
            ],
            "layout" => Dict("title"=>"Fraction with red opinion",
                             "showlegend" => false,
                             "xaxis"=>Dict("title"=>"Iteration #"),
                             "yaxis" => Dict("range"=>[0.0,1.0]))
        )
    )
end
run_server(app, "127.0.0.1", 8087)
