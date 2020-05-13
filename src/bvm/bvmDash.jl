
import HTTP
using Dash
using DataFrames, DataFramesMeta, CSV

include("bvm.jl")

using .bvm

external_stylesheets = ["https://codepen.io/chriddyp/pen/bWLwgP.css"]

app = dash("Binary Voter Model", external_stylesheets=external_stylesheets)

app.layout = html_div(id="top") do
    html_h1("Binary Voter Model"),

    html_div(id="inputs-div") do
        html_div(id="inputs-div") do
            dcc_radioitems(
                options=[Dict("label" => "node influences neighbor",
                            "value" => "influencer"),
                         Dict("label" => "neighbor influences node",
                            "value" => "influencee")],
                value="influencer",
                labelStyle=Dict("display" => "inline-block")
            )
        end
    end

end

run_server(app, "127.0.0.1", 8087)
