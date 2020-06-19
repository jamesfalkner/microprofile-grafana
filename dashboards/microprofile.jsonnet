local grafana = import 'grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local singlestat = grafana.singlestat;
local graph = grafana.graphPanel;
local prometheus = grafana.prometheus;
local template = grafana.template;

// header width, panel width, panel height
local hh = 2;
local pw = 6;
local ph = 6;

// the incoming microprofile metrics spec
local src = std.extVar('src');

local newdash = dashboard.new(
  'MicroProfile Metrics %TIMESTAMP%',
    refresh='5s',
    time_from='now-5m',
    schemaVersion=16,
    tags=['java','microprofile'],
    editable=true
)
.addTemplate(
  grafana.template.datasource(
    'PROMETHEUS_DS',
    'prometheus',
    'Prometheus',
    hide='label',
  )
)
.addTemplate(
  template.new(
    'env',
    '$PROMETHEUS_DS',
    'label_values(base_thread_count, env)',
    label='Environment',
    refresh='time',
  )
)
.addTemplate(
  template.new(
    'job',
    '$PROMETHEUS_DS',
    'label_values(base_thread_count{env="$env"}, job)',
    label='Job',
    refresh='time',
  )
)
.addTemplate(
  template.new(
    'instance',
    '$PROMETHEUS_DS',
    'label_values(base_thread_count{env="$env",job="$job"}, instance)',
    label='Instance',
    refresh='time',
  )
);

// generate tags for grafana legend based on metadata. e.g. tag={{tag}} footag={{footag}}
local getTags(tags, type) =
  local tagStr = std.join('/',
    std.uniq(
      std.sort(std.map(function(tag)
        local tagEls = std.splitLimit(tag, '=', 1);

        std.format('%s={{%s}}', [tagEls[0], tagEls[0]]),
        std.flattenArrays(tags)))
      )
    );

  if type == 'timer' then std.format('%s%s', ['{{job}} q={{quantile}}/', tagStr])
  else '{{job}} ' + tagStr;

// map metric name to the OpenMetrics format based on microprofile metrics rules
local makeOpenMetricName(name, type, unit, scope) =
  local counterNameHasSuffix = (std.endsWith(name, 'count') || std.endsWith(name, 'total'));
  local r1 = scope + '_' + std.strReplace(name, '.', '_');
  local r2 = std.strReplace(std.strReplace(r1, ' ', '_'), '__', '_');
  local r3 =
    if (std.endsWith(unit, 'bytes') || std.endsWith(unit, 'bits'))
    then r2 + '_bytes'
    else if unit == 'percent'
    then r2 + '_percent'
    else if type == 'simple timer'
    then r2 + '_elapsedTime_seconds'
    else if type == 'timer'
    then r2 + '_seconds'
    else if type == 'meter'
    then r2 + '_rate_per_second'
    else if (type == 'counter') && std.endsWith(unit, 'seconds')
    then r2  + '_total_seconds'
    else if (type == 'counter') && !std.endsWith(r2, '_total')
    then r2  + '_total'
    else if type == 'concurrent gauge'
    then r2  + '_current'
    else if std.endsWith(unit, 'seconds')
    then r2 + '_seconds'
    else if unit == 'none'
    then r2
    else r2 + '_' + unit;

  r3;

// add a basic graph or gauge
local addSimple(func, metricObj) =
  local scope = metricObj.scope;
  local unit = src[scope][metricObj.name]['unit'];
  local type = src[scope][metricObj.name]['type'];
  local tags = src[scope][metricObj.name]['tags'];
  local desc = src[scope][metricObj.name]['description'];
  local dispname = src[scope][metricObj.name]['displayName'];
  local omn = makeOpenMetricName(metricObj.name, type, unit, scope);

    if metricObj.name != '' then
      func.addPanel(
        (if type == "gauge" && std.findSubstr('memory', metricObj.name) == [] then
          singlestat.new(
              if dispname != "" then dispname else metricObj.name,
              format = (if unit == 'percent' then 'percent' else if std.findSubstr('second', unit) != [] then 's' else 'short'),
              valueFontSize='110%',
              datasource='-- Mixed --',
              span=2,
              description=desc,
              sparklineShow=true,
              sparklineFull=true,
              valueName='current',

          )
          .addTarget(
              prometheus.target(
              omn + '{env="$env",job="$job",instance=~`[[instance]]`}',
              datasource='$PROMETHEUS_DS',
              legendFormat=getTags(tags, type)
            )
          )
        else
          graph.new(
            if dispname != "" then dispname else metricObj.name,
            span=6,
            min_span=6,
            format = (if unit == 'percent' then 'percent' else  if unit == 'bytes' then 'bytes' else 'short'),
            fill=1,
            min=0,
            decimals=2,
            description=desc,
            datasource='-- Mixed --',
            legend_values=true,
            legend_min=false,
            legend_max=false,
            legend_current=true,
            legend_total=false,
            legend_avg=false,
            legend_alignAsTable=true,
          )
          .addTarget(
              prometheus.target(
              omn + '{env="$env",job="$job",instance=~`[[instance]]`}',
              datasource='$PROMETHEUS_DS',
              legendFormat=getTags(tags, type)
              )
          )), gridPos={
              x: metricObj.xpos,
              y: metricObj.ypos,
              w: 6,
              h: 6,
          }
       )
    else func;

local baseMetrics = if std.objectHas(src, 'base') then src.base else {};
local vendorMetrics = if std.objectHas(src, 'vendor') then src.vendor else {};
local appMetrics = if std.objectHas(src, 'application') then src.application else {};

// first start with application metrics header
local appdash = newdash.addPanel(
  row.new(
    title='MicroProfile App Metrics',
    showTitle=true,
    titleSize='h1'
  ), gridPos={
    x: 0,
    y: 0,
    w: 24,
    h: 2
  }
);

// then add application metrics
local appformed = std.foldl(addSimple,
          std.mapWithIndex(function(idx,el) {name: el, xpos: idx%4 * 6, ypos: 2 + (6 * std.floor((idx/4))), scope: 'application'},
          std.objectFields(appMetrics)), appdash);

// then add vendor header
local vendordash = appformed.addPanel(
  row.new(
    title='MicroProfile Vendor Metrics',
    showTitle=true,
    titleSize='h1'
  ), gridPos={
    x: 0,
    y: 2 + (6 * std.ceil(std.length(appMetrics) / 4)),
    w: 24,
    h: 2
  }
);

// and vendor metrics
local vendorformed = std.foldl(addSimple,
          std.mapWithIndex(function(idx,el) {name: el, xpos: idx%4 * 6, ypos: 2 + (6 * std.ceil(std.length(vendorMetrics) / 4) + 2 + (6 * std.floor((idx/4)))), scope: 'vendor'},
          std.objectFields(vendorMetrics)), vendordash);

// finally base metrics header
local basedash = vendorformed.addPanel(
  row.new(
    title='MicroProfile Base Metrics',
    showTitle=true,
    titleSize='h1'
  ), gridPos={
    x: 0,
    y: 2 + (6 * std.ceil(std.length(appMetrics) / 4)) + 2 + (6 * std.ceil(std.length(vendorMetrics) / 4)),
    w: 24,
    h: 2
  }
);

// and add base metrics
std.foldl(addSimple,
          std.mapWithIndex(function(idx,el) {name: el, xpos: idx%4 * 6, ypos: 2 + (6 * std.ceil(std.length(appMetrics) / 4)) + 2 + (6 * std.ceil(std.length(vendorMetrics) / 4)) + 2 + (6 * std.floor((idx/4))), scope: 'base'},
          std.objectFields(baseMetrics)), basedash)
