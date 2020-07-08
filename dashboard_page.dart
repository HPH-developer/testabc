import 'dart:async';
import 'dart:core';
import 'package:app/blocs/application_bloc.dart';
import 'package:app/blocs/bloc_provider.dart';
import 'package:app/domain/api_client.dart';
import 'package:app/local/gift_cache.dart';
import 'package:app/local/sku_cache.dart';
import 'package:app/localizations/message_localizations.dart';
import 'package:app/model/gift_model.dart';
import 'package:app/model/sku_model.dart';
import 'package:app/model/trmrp2_h_model.dart';
import 'package:app/route/routing.dart';
import 'package:app/ui/customs/dialog_handle_result.dart';
import 'package:app/ui/helper/ui_compute.dart';
import 'package:app/ui/pages/attendance/attendance_page.dart';
import 'package:app/ui/pages/exchange_gifts/exchange_gifts_page.dart';
import 'package:app/ui/pages/notification/notifications_page.dart';
import 'package:app/ui/pages/report_daily/report_daily_page.dart';
import 'package:app/ui/pages/tr_mrp2/tr_mrp2_h_page.dart';
import 'package:app/ui/widgets/loader.dart';
import 'package:app/utils/constants.dart';
import 'package:app/utils/hex_color.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

class DashboardPage extends StatefulWidget {
  DashboardPage({Key key}) : super(key: key);

  @override
  DashboardPageState createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage>
    with AutomaticKeepAliveClientMixin {
  ApplicationBloc _appBloc;

  Completer<GoogleMapController> mapsController = Completer();
  double widthItemFeature = 0;
  double heightItemFeature = 0;
  bool isLoading = false;
  double latGPS = 0;
  double longGPS = 0;

  @override
  void initState() {
    _appBloc = BlocProvider.of<ApplicationBloc>(context);
    addProduct();
    addGift();
    if (!_appBloc.isLoadGPS) {
      onGetCurrentPosition();
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // todo handle

  addProduct() async {
    await ProductCache()
        .setData(SkuModel.getListSimpleData())
        .then((_) {
      print('add success product');
    });
//    await ProductCache().deleteAll();
  }

  addGift() async {
    await GiftCache()
        .setData(GiftModel.getListSimpleData())
        .then((_) {
      print('add success gift');
    });
//    await ProductCache().deleteAll();
  }

  onFailedFunc(String message) {
    showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return DialogHandleResult(
            title: 'Thất bại',
            message: message,
            actionState: ActionState.FAILED,
            btnYesText: 'OK',
          );
        });
  }

  onGetCurrentPosition() async {
    setIsLoading(true);
    await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((position) {
      setState(() {
        _appBloc.latGPS = position.latitude;
        _appBloc.longGPS = position.longitude;
        _appBloc.isLoadGPS = true;
      });
      setIsLoading(false);
    }).catchError((err) {
      print('error rồi');
      setIsLoading(false);
      onFailedFunc(
          MessageLocalizations.of(context).can_accepted_permision_location);
    });
  }

  setIsLoading(bool value) {
    setState(() {
      isLoading = value;
    });
  }

  goAttendance({AttendanceType type}) {
    Routing().navigate2(context, AttendancePage(type: type));
  }

  goReportDaily({ReportDailyType type}) {
    Routing().navigate2(context, ReportDailyPage(type: type));
  }

  goExchangeGifts(){
    Routing().navigate2(context, ExchangeGiftsPage());
  }

  goTRMRP2H() {
    Routing().navigate2(context, TRMRP2HPage());
  }

  // todo render widgets

  _renderFeature(
      {String title,
      IconData iconData,
      String title_tag = null,
      Function onTap = null}) {
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.all(Radius.circular(15)),
      color: HexColor(appWhite),
      animationDuration: Duration(seconds: 1),
      child: InkWell(
        borderRadius: BorderRadius.all(Radius.circular(15)),
        onTap: () {
          if (onTap != null) {
            onTap();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
          padding: EdgeInsets.symmetric(
              vertical: UICompute.conv(20), horizontal: UICompute.conv(10)),
          width: widthItemFeature,
          height: heightItemFeature,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(iconData,
                  size: UICompute.conv(32), color: HexColor(appTab80)),
              Container(
                height: UICompute.conv(40),
                alignment: Alignment.center,
                child: Hero(
                  tag: title_tag != null ? title_tag : null,
                  child: Text(title,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: ptTitle(context).copyWith(
                        fontSize: UICompute.conv(12),
                        fontFamily: "hknova_regular",
                      )),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    widthItemFeature = deviceWidth(context) / 3 - UICompute.conv(15);
    heightItemFeature = deviceWidth(context) / 3 - UICompute.conv(15);
    return Scaffold(
      appBar: new AppBar(
        title: Text(MessageLocalizations.of(context).home.toUpperCase(),
            style: ptHeadline(context).copyWith()),
        centerTitle: true,
        elevation: 0,
        brightness: Brightness.light,
        backgroundColor: HexColor(appBarColor),
//        backgroundColor: Colors.transparent,
        leading: Container(
          margin: EdgeInsets.all(UICompute.conv(10)),
          decoration: BoxDecoration(
              border: Border.all(
                  color: HexColor(appColor),
                  style: BorderStyle.solid,
                  width: 1),
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage(IMAGE_NONE2),
                fit: BoxFit.fill,
              )),
        ),
      ),
      backgroundColor: HexColor(appWhite),
//      backgroundColor: Colors.transparent,
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            key: Key('scroll_main'),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: UICompute.conv(10)),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: UICompute.conv(10)),
                  Row(
                    children: <Widget>[
                      Text(
                        "Hi, ",
                        style: ptHeadline(context).copyWith(),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          "Neymar JR!",
                          style: ptHeadline(context).copyWith(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: UICompute.conv(5)),
                  Text("Wellcome to IDS program",
                      style:
                          ptBody1(context).copyWith(color: HexColor(appText))),
                  SizedBox(height: UICompute.conv(20)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _renderFeature(
                          title: MessageLocalizations.of(context).attendace_in,
                          iconData: Icons.insert_invitation,
                          title_tag: 'tag_title_in',
                          onTap: () {
                            goAttendance(type: AttendanceType.IN);
                          }),
                      _renderFeature(
                          title:
                              MessageLocalizations.of(context).report_emergency,
                          iconData: Icons.ring_volume,
                          title_tag: Uuid().v1().replaceAll('-', ''),
                          onTap: () {}),
                      _renderFeature(
                          title: MessageLocalizations.of(context).report_price,
                          iconData: Icons.monetization_on,
                          title_tag: Uuid().v1().replaceAll('-', ''),
                          onTap: () {
                            goReportDaily(type: ReportDailyType.REPORT_PRICE);
                          }),
                    ],
                  ),
                  SizedBox(height: UICompute.conv(15)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _renderFeature(
                          title: MessageLocalizations.of(context)
                              .report_off_take_volume,
                          iconData: Icons.assignment,
                          title_tag: Uuid().v1().replaceAll('-', ''),
                          onTap: () {
                            goReportDaily(
                                type: ReportDailyType.REPORT_OFF_TAKE_VOLUMN);
                          }),
                      _renderFeature(
                          title: MessageLocalizations.of(context).report_posm,
                          iconData: Icons.assignment,
                          title_tag: Uuid().v1().replaceAll('-', ''),
                          onTap: () {
                            goReportDaily(type: ReportDailyType.REPORT_POSM);
                          }),
                      _renderFeature(
                          title: MessageLocalizations.of(context).report_stock,
                          iconData: Icons.assignment,
                          title_tag: Uuid().v1().replaceAll('-', ''),
                          onTap: () {
                            goReportDaily(type: ReportDailyType.REPORT_STOCK);
                          }),
                    ],
                  ),
                  SizedBox(height: UICompute.conv(15)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _renderFeature(
                          title: MessageLocalizations.of(context).request_gift,
                          iconData: Icons.redeem,
                          title_tag: Uuid().v1().replaceAll('-', ''),
                          onTap: () {}),
                      _renderFeature(
                          title: MessageLocalizations.of(context).exchange_gifts,
                          iconData: Icons.redeem,
                          title_tag: Uuid().v1().replaceAll('-', ''),
                          onTap: () {
                            goExchangeGifts();
                          }),
                      _renderFeature(
                          title: MessageLocalizations.of(context).upload_data,
                          iconData: Icons.cloud_upload,
                          title_tag: Uuid().v1().replaceAll('-', ''),
                          onTap: () {}),
                    ],
                  ),
                  SizedBox(height: UICompute.conv(15)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _renderFeature(
                          title: MessageLocalizations.of(context).attendace_out,
                          iconData: Icons.insert_invitation,
                          title_tag: 'tag_title_out',
                          onTap: () {
                            goAttendance(type: AttendanceType.OUT);
                          }),
                      _renderFeature(
//                          title: MessageLocalizations.of(context).attendace_out,
                          title: "MRP2",
                          title_tag: 'tag_title_mrp2',
                          iconData: Icons.insert_invitation,
                          onTap: () {
                            goTRMRP2H();
                          }),
                    ],
                  ),
                  SizedBox(height: UICompute.conv(20)),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: !isLoading ? Container() : Loader(),
          )
        ],
      ),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
