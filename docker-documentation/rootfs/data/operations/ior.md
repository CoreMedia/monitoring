# CoreMedia Monitoring Toolbox - Operations Guide

## IOR

**IOR** steht als Abkürzung für "_Interoperable Object Reference, eine Objektreferenz auf ein CORBA-Objekt_"

----

Die Kommunikation im CoreMedia-Umfeld findet bidirektional zwischen allen Contentservern sowie zwischen CAE und RLS statt.

Der "Client" fragt seinen "Server" über eine IOR-URI an und bekommt eine URI zurück, über der die weiter Kommunikation stattfindet.

----

Die IOR wird von Content-Servern zur Verfügung gestellt und kann über HTTP abgerufen werden:

 - **CMS** `curl http://${SERVER}:40180/coremedia/ior`
 - **MLS** `curl http://${SERVER}:40280/coremedia/ior`
 - **WFS** `curl http://${SERVER}:40380/workflow/ior`
 - **RLS** `curl http://${SERVER}:42180/coremedia/ior`

 ----

Online-Tool zum parsen einer IOR: [ILU IOR Parser](http://www2.parc.com/istl/projects/ILU/parseIOR/)

Die CoreMedia Tools bieten ebenfalls einen IOR Parser:
```bash
bin/cm ior $(curl --silent localhost:40280/coremedia/ior)
IOR<IDL:hox/corem/corba/LoginServiceWithProtocolVersion:1.0><IIOP:1.2:moebius-ci-02-moebius-tomcat-0-cms.coremedia.vm:40283>
  { TAG_CODE_SETS: {ForCharData={native_code_set="ISO 8859-1", conversion_code_sets=[UTF-8, "ISO 646:1991 IRV"]}, ForWcharData={native_code_set=UTF-16, conversion_code_sets=["ISO/IEC 10646-1:1993, UCS-2, Level 1"]}} },
  { TAG_RMI_CUSTOM_MAX_STREAM_FORMAT: 2 }
```

----

## Operating

| Fehler  | ToDo      |
| :------ | :-------- |
| IOR steht nicht zur Verfügung | den Service kontrollieren und ggf. neu starten |
