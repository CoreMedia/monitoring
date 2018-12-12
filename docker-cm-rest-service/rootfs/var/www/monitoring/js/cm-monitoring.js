
$(document).ready(function() {

  var $spinner = $('#spinner');
  var $dialog = $('#modal-overflow');
  var $table = $('#monitoring-hosts');

  $spinner.hide();

  // initial load of our monitored hosts
  load_monitoring_hosts();

  // then use an interval for an update
  setInterval(function() {
    load_monitoring_hosts();
  }, 60000 ); // - 30000 = 30 sek.! ( 120000 == 2 minuten) ziel sollte sein zwischen 1 und 3 minuten

  // set focus
  $('#add-host-text').focus();

  // add host to monitoring
  $("#add-host-button").on("click", function(event) {

    event.preventDefault();

    var $a = $('#add-host-text').val();

    if($a == '') {
      return;
    }

    var message = '';
    var params = '';

    $spinner.show();

    $.ajax({
      type: 'post',
      dataType: 'json',
      url: '/web/ajax/add-host/' + $a,
      params: params,
      success: function(data) {
        console.debug(data)
        message = data.message
      },
      complete: function(xhr, textStatus) {
        console.log(xhr.responseJSON);
        status  = xhr.responseJSON.status;
        message = xhr.responseJSON.message;

        if(status == 200) { notification( 'success', message ) }
        else if(status == 400) { notification( 'primary', message ) }
        else if(status == 401) { notification( 'danger', message ) }
        else if(status == 404) { notification( 'danger', message ) }
        else if(status == 409) { notification( 'warning', message ) }
        else { notification( 'primary', message ) }
      }
    });
    $spinner.hide();
    $('#add-host-text').val('');
  });


  $table.on('click', '.delete-host', function() {

    var $t = $(this)
    var $b = $t.closest('tr');
    var $hostname = $b.data('hostname');

    var dialogHTML = '';

    dialogHTML += '<div class="uk-modal-dialog">';
    dialogHTML += '  <button class="uk-modal-close-default" type="button" uk-close></button>';
    dialogHTML += '  <div class="uk-modal-header"><h2 class="uk-modal-title">delete Host ' + $hostname + ' from monitoring</h2></div>';
    dialogHTML += '  <div class="uk-modal-body" uk-overflow-auto>';
    dialogHTML += '    <p>schould delete this host from monitoring?</p>';
    dialogHTML += '  </div>';
    dialogHTML += '  <div class="uk-modal-footer uk-text-right">';
    dialogHTML += '    <button class="uk-button uk-button-default uk-modal-close" type="button">Cancel</button>';
    dialogHTML += '    <button id="delete" class="uk-button uk-button-primary" type="button">Delete</button>';
    dialogHTML += '  </div>';
    dialogHTML += '</div>';

    $dialog.html(dialogHTML);

    UIkit.modal.confirm('<b>Delete Host ' + $hostname + ' from monitoring</b>', {
      labels: {
        cancel: 'Cancel',
        ok: 'DELETE this host'
      }
    }).then(function () {
      $spinner.show();

      console.log('Confirmed.')

      $.ajax({
        type: 'delete',
        async: true,
        dataType: 'json',
        url: '/api/v2/host/' + $hostname,

        success: function(data) {
          console.debug(data)
          message = data.message
        },
        complete: function(xhr, textStatus) {
          status  = xhr.responseJSON.status;
          message = xhr.responseJSON.message;
          console.log(xhr.responseJSON);

          if(status == 200) { notification( 'success', message ) }
          else if(status == 400) { notification( 'primary', message ) }
          else if(status == 401) { notification( 'danger', message ) }
          else if(status == 404) { notification( 'danger', message ) }
          else if(status == 409) { notification( 'warning', message ) }
          else { notification( 'primary', message ) }

          load_monitoring_hosts();
        }
      });

      $spinner.hide();
    }, function () {
      console.log('Rejected.')
    });
  });

  $table.on('click', '.host-information', function() {

    var $t = $(this)
    var $b = $t.closest('tr');
    var $hostname = $b.data('hostname');

    console.debug($hostname);

    $.ajax({
      type: 'get',
      async: true,
      dataType: 'json',
      url: '/api/v2/host/' + $hostname,
      complete: function(xhr, textStatus) {
        var json   = xhr.responseJSON
        var status = json.status;

        if(status == 200) {

          var d = {}
          var s = {}
          var services = []

          var li = '';

          $.each(json, function (k,v) {
            if(v['dns'] !== undefined) { d = v['dns'] }
            if(v['services'] !== undefined) { s = v['services'] }
            services = Object.keys(s).sort();
          });

          var ul = $('<ul>');
          var ul_dns = '';
          var ul_services = '';

          $.each(d, function(k,v,) {
            ul_dns = ul.append($("<li>").text(k + ': ' +v));
          });
          ul_services = $('<ul>').append(
            services.map(c => $("<li>").text(c) )
          );

          var dialogHTML = '';

          dialogHTML += '<div class="uk-modal-dialog">';
          dialogHTML += '  <button class="uk-modal-close-default" type="button" uk-close></button>';
          dialogHTML += '  <div class="uk-modal-header"><h2 class="uk-modal-title">information about Host ' + $hostname + '</h2></div>';
          dialogHTML += '  <div class="uk-modal-body" uk-overflow-auto>';
          dialogHTML += '    <span><strong>DNS:</strong></span>';
          dialogHTML += ul_dns.html();
          dialogHTML += '    <span><strong>Services:</strong></span>';
          dialogHTML += ul_services.html();
          dialogHTML += '  </div>';
          dialogHTML += '  <div class="uk-modal-footer uk-text-right">';
          dialogHTML += '    <button class="uk-button uk-button-default uk-modal-close" type="button">Close</button>';
          dialogHTML += '  </div>';
          dialogHTML += '</div>';

          $dialog.html(dialogHTML);
          UIkit.modal($dialog).show();
        }
        else {}
      }
    });
  });


  $('#about').on('click', function(event) {

    event.preventDefault();
    event.target.blur();

    $.ajax({
      type: 'get',
      async: true,
      dataType: 'json',
      url: '/web/ajax/CHANGELOG',
      complete: function(xhr, textStatus) {
        var json   = xhr.responseJSON
        var status = xhr.status;

        if(status == 200) {

          var version = '';
          var date = '';
          var changes = '';

          $.each(json, function (k,v) {
            if(k !== undefined && k === 'version' && v !== undefined) { version = v }
            if(k !== undefined && k === 'date' && v !== undefined) { date = v }
            if(k !== undefined && k === 'changes' && v !== undefined) { changes = v }
          });

          ul_services = $('<ul>').append(
            changes.map(c => $("<li>").text(c) )
          );

          var dialogHTML = '';

          dialogHTML += '<div class="uk-modal-dialog">';
          dialogHTML += '  <button class="uk-modal-close-default" type="button" uk-close></button>';
          dialogHTML += '  <div class="uk-modal-header"><h2 class="uk-modal-title">CoreMedia Monitoring Toolbox</h2></div>';
          dialogHTML += '  <div class="uk-modal-body" uk-overflow-auto>';
          dialogHTML += '    <p>Version <strong>' + version + '</strong> (' + date + ')</p>';
          dialogHTML += '    <span><strong>Changelog</strong></span>';
          dialogHTML += $('<ul>').append(
            changes.map(c => $("<li>").text(c) )
          ).html();
          dialogHTML += '  </div>';
          dialogHTML += '  <div class="uk-modal-footer uk-text-right">';
          dialogHTML += '    <button class="uk-button uk-button-default uk-modal-close uk-button-primary" type="button">Close</button>';
          dialogHTML += '  </div>';
          dialogHTML += '</div>';

          $dialog.html(dialogHTML);

          UIkit.modal($dialog).show();

        }
      }
    });
  });

});




/**
 *  annotations
 */
$(function() {

  $('#monitoring-hosts').on('click', '.add-annotation-for-host', function(e) {

    e.preventDefault();
    e.target.blur();

    var $t = $(this)
    var $b = $t.closest('tr');
    var $hostname = $b.data('hostname');

    var dialogHTML = '';

    dialogHTML += '<div class="uk-modal-dialog">';
    dialogHTML += '  <button class="uk-modal-close-default" type="button" uk-close></button>';
    dialogHTML += '  <div class="uk-modal-header"><h2 class="uk-modal-title">Add Annotation for Host ' + $hostname + '</h2></div>';
    dialogHTML += '  <div class="uk-modal-body" uk-overflow-auto>';

    dialogHTML += '    <ul class="uk-tab" data-uk-tab="{connect:\'#my-id\'}">';
    dialogHTML += '      <li><a href="">Tab 1</a></li>';
    dialogHTML += '      <li><a href="">Tab 2</a></li>';
    dialogHTML += '      <li><a href="">Tab 3</a></li>';
    dialogHTML += '    </ul>';
    dialogHTML += '    <ul id="my-id" class="uk-switcher uk-margin">';
    dialogHTML += '      <li><a href="#" id="autoplayer" data-uk-switcher-item="next"></a>';
    dialogHTML += '       This slide contains a hidden link, that selects the next slide when clicked. The click is simulated by jacascript to mimic autoplay.';
    dialogHTML += '        </li>';
    dialogHTML += '      <li>Content 2';
    dialogHTML += '        <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>';
    dialogHTML += '      </li>';
    dialogHTML += '      <li>Content 3</li>';
    dialogHTML += '    </ul>';

    dialogHTML += '    <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>';
    dialogHTML += '  </div>';
    dialogHTML += '  <div class="uk-modal-footer uk-text-right">';
    dialogHTML += '    <button class="uk-button uk-button-default uk-modal-close" type="button">Cancel</button>';
    dialogHTML += '    <button id="add-annotation" class="uk-button uk-button-primary" type="button">Save</button>';
    dialogHTML += '  </div>';
    dialogHTML += '</div>';

    $dialog.html(dialogHTML);

    UIkit.modal($dialog).show();

    $dialog.on('click', '#add-annotation', function(e) {

      console.debug($hostname);
    });
  });

});

function notification( status, message ) {

  UIkit.notification({
    message: message,
    status: status,
    pos: 'top-right',
    timeout: 5000
  });
}


function load_monitoring_hosts() {

  var $table = $('#monitoring-hosts');
  var trHTML = '';

  $.ajax({
    type: 'get',
    async: true,
    dataType: 'json',
    url: '/api/v2/host',
    success: function(data) {

      $("#monitoring-hosts > tbody").html('');

      $.each(data, function(index, elem) {

        console.debug('index ' + index);
        console.debug('elem  ' + elem);

        if(index === 'status') {
          // return false; //this is equivalent of 'break' for jQuery loop
          return; //this is equivalent of 'continue' for jQuery loop
        }

        if(elem === undefined) {
          console.debug('elem are undef')
          return;
        }
        if(elem.dns === undefined) {
          console.debug('elem.dns are undef')
          console.debug(elem)
          return;
        }

        trHTML  = '<tr data-hostname="'+elem.dns.short+'">';
        trHTML += '<td><!--<span class="uk-icon-button" uk-icon="laptop"></span>--></td>';
        trHTML += '<td>' + elem.dns.short + '</td>';
        trHTML += '<td>' + toDate(elem.status.created) + '</td>';
        trHTML += '<td>';
        trHTML += ' <!-- <a href="#" class="uk-icon-link add-annotation-for-host" uk-icon="commenting" uk-tooltip="add annotation"></a> -->';
        trHTML += ' <a href="#" class="uk-icon-link host-information uk-padding-small" uk-icon="info" uk-tooltip="information"></a>';
        trHTML += ' <a href="#" class="uk-icon-link delete-host uk-text-danger uk-padding-small" uk-icon="trash" uk-tooltip="delete host"></a>';
        trHTML += '</td>';
        trHTML += '</tr>';

        $table.append(trHTML);
      });

    },
    statusCode: {
      200: function() { /*console.debug('200')*/ },
      401: function() { /*console.debug('401')*/ },
      404: function() { /*console.debug('404')*/ }
    }
  });
}


function toDate(dateStr) {

  const [date, time] = dateStr.split(" ")
  const [year, month, day] = date.split("-")

//   console.debug(time)

  d = new Date(year, month, day)

  return pad(d.getDate()) + '.' + pad(d.getMonth()) + '.' + d.getFullYear() + '  ' + time;
}

function pad(n){ return n<10 ? '0'+n : n }


