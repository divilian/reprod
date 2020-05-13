
import HTTP
using Dash
using DataFrames, DataFramesMeta, CSV

include("bvm.jl")

using .bvm

external_stylesheets = [
    "https://codepen.io/chriddyp/pen/bWLwgP.css",
    "http://stephendavies.org/dash.css"]

app = dash("Binary Voter Model", external_stylesheets=external_stylesheets)

app.layout = html_div(id="top") do
    html_h1("Binary Voter Model"),

    html_div(id="inputs-div") do
        html_div(id="er-outer-div") do
            html_h3("Erdos-Renyi graph parameters"),
            html_div(id="er-div", className="widgets") do
                html_span("N "),
                dcc_input(
                    id="n",
                    type="number",
                    min=10, max=50, step=1,
                    value=10,
                    style=Dict("width" => "80px")
                ),
                html_span("p "),
                dcc_input(
                    id="p",
                    type="number",
                    value=.2,
                    min=0.1, max=1.0, step=.05,
                    style=Dict("width" => "80px")
                )
            end
        end,
        html_div(id="influences-outer-div") do
            html_h3("Variations"),
            html_div(id="influences-div", className="widgets") do
                html_span("node"),
                dcc_dropdown(
                    id="influencer",
                    options=[Dict("label" => "influences",
                                "value" => "influencer"),
                             Dict("label" => "is influenced by",
                                "value" => "influencee")],
                    style=Dict("width" => "150px", "display" => "inline-block"),
                    value="influencer"
                ),
                html_span("neighbor")
            end,
            html_div(id="replacement-div", className="widgets") do
                html_span("choose nodes"),
                dcc_dropdown(
                    id="influencer",
                    options=[Dict("label" => "with",
                                "value" => "influencer"),
                             Dict("label" => "without",
                                "value" => "influencee")],
                    style=Dict("width" => "120px", "display" => "inline-block"),
                    value="influencee",
                ),
                html_span("replacement")
            end
        end
    end

end

run_server(app, "127.0.0.1", 8087)
