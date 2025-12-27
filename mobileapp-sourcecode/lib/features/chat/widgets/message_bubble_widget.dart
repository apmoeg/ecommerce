import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/domain/models/message_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/controllers/chat_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/screens/media_viewer_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/controllers/localization_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/color_resources.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_image_widget.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class MessageBubbleWidget extends StatelessWidget {
  final Message message;
  final Message? previous;
  final Message? next;
  const MessageBubbleWidget({super.key, required this.message, this.previous, this.next});

  @override
  Widget build(BuildContext context) {

    final ChatController chatController = Provider.of<ChatController>(context, listen: false);

    List<Attachment> images = [];
    List<Attachment> files = [];

    bool isMe = message.sentByCustomer!;

    String? image = chatController.userTypeIndex != 0 ?
    message.sellerInfo != null? message.sellerInfo?.shops![0].imageFullUrl?.path : '' : message.deliveryMan?.imageFullUrl?.path;

    if(message.attachment != null) {
      for(Attachment attachment in message.attachment!){
        if(attachment.type == 'media'){
          images.add(attachment);

        }else if (attachment.type == 'file') {
          files.add(attachment);
        }
      }
    }

    return Consumer<ChatController>(
        builder: (context, chatProvider,child) {
          String chatTime  = chatProvider.getChatTime(message.createdAt!, message.createdAt);
          bool isSameUserWithPreviousMessage = chatProvider.isSameUserWithPreviousMessage(previous, message);
          bool isSameUserWithNextMessage = chatProvider.isSameUserWithNextMessage(message, next);
          bool isLTR = Provider.of<LocalizationController>(context, listen: false).isLtr;
          String previousMessageHasChatTime = next != null? chatProvider.getChatTime(next!.createdAt!, message.createdAt) : "";

        return Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end:CrossAxisAlignment.start, children: [
          Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [

                ((!isMe && !isSameUserWithPreviousMessage) ||  (!isMe && isSameUserWithPreviousMessage)) &&
                    chatProvider.getChatTimeWithPrevious(message, previous).isNotEmpty ?
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Container( width: Dimensions.paddingSizeExtraLarge + 5, height: Dimensions.paddingSizeExtraLarge + 5,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(color: Theme.of(context).primaryColor)),
                      child: ClipRRect(borderRadius: BorderRadius.circular(20.0),
                          child: CustomImageWidget(
                              fit: BoxFit.cover, width: Dimensions.paddingSizeExtraLarge + 5,
                              height: Dimensions.paddingSizeExtraLarge + 5, image: '$image'))),
                ) :  !isMe ? const SizedBox(width: Dimensions.paddingSizeExtraLarge + 5,) : const SizedBox(),


                if(message.message != null && message.message!.isNotEmpty)
                  Flexible(child: InkWell(
                    onTap: (){
                      chatProvider.toggleOnClickMessage(onMessageTimeShowID :
                      message.id.toString());
                    },
                    child: Container(
                      margin: isMe && isLTR ? EdgeInsets.fromLTRB(70, 2, isMe ? 0 : 10, 2) : EdgeInsets.fromLTRB(isMe ? 0 : 10, 2, isLTR ? 70 : 10, 2),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(

                          borderRadius: isMe && (isSameUserWithNextMessage || isSameUserWithPreviousMessage) ? BorderRadius.only(
                            topRight: Radius.circular(isSameUserWithNextMessage && isLTR && chatTime == "" ? Dimensions.radiusSmall : Dimensions.radiusExtraLarge + 5),
                            bottomRight: Radius.circular(isSameUserWithPreviousMessage && isLTR && previousMessageHasChatTime == "" ? Dimensions.radiusSmall : Dimensions.radiusExtraLarge + 5),
                            topLeft: Radius.circular(isSameUserWithNextMessage && !isLTR && chatTime == ""? Dimensions.radiusSmall : Dimensions.radiusExtraLarge + 5),
                            bottomLeft: Radius.circular(isSameUserWithPreviousMessage && !isLTR && previousMessageHasChatTime == ""? Dimensions.radiusSmall :Dimensions.radiusExtraLarge + 5),

                          ) : !isMe && (isSameUserWithNextMessage || isSameUserWithPreviousMessage) ? BorderRadius.only(
                            topLeft: Radius.circular(isSameUserWithNextMessage && isLTR && chatTime == ""? Dimensions.radiusSmall : Dimensions.radiusExtraLarge + 5),
                            bottomLeft: Radius.circular( isSameUserWithPreviousMessage && isLTR && previousMessageHasChatTime == "" ? Dimensions.radiusSmall : Dimensions.radiusExtraLarge + 5),
                            topRight: Radius.circular(isSameUserWithNextMessage && !isLTR && chatTime == ""? Dimensions.radiusSmall : Dimensions.radiusExtraLarge + 5),
                            bottomRight: Radius.circular(isSameUserWithPreviousMessage && !isLTR && previousMessageHasChatTime == ""? Dimensions.radiusSmall :Dimensions.radiusExtraLarge + 5),

                          ) : BorderRadius.circular(Dimensions.radiusExtraLarge + 5),

                          color: isMe ? ColorResources.getImageBg(context) : ColorResources.chattingSenderColor(context)),
                      child: (message.message != null && message.message!.isNotEmpty) ? Text(message.message!,
                        textAlign: TextAlign.justify,
                        style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault,
                            color : isMe? Colors.white: Theme.of(context).textTheme.bodyLarge?.color),
                      ) : const SizedBox.shrink(),
                    ),
                  ))
              ],
          ),


          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: AnimatedContainer(
              curve: Curves.fastOutSlowIn,
              duration: const Duration(milliseconds: 500),
              height: chatProvider.onMessageTimeShowID == message.id.toString() ? 25.0 : 0.0,
              child: Padding(
                padding: EdgeInsets.only(
                  top: chatProvider.onMessageTimeShowID == message.id.toString() ?
                  Dimensions.paddingSizeExtraSmall : 0.0,
                ),
                child: Text(chatProvider.getOnPressChatTime(message) ?? "", style: textRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall
                )),
              ),
            ),
          ),


          if(images.isNotEmpty) const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          _MediaGridWidget(images: images, isMe: isMe),


          if(files.isNotEmpty)Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [

              files.isNotEmpty ?
              Directionality(
                textDirection: isMe  && isLTR?
                TextDirection.rtl : !isLTR && !isMe?
                TextDirection.rtl : TextDirection.ltr,

                child: Padding(
                  padding: EdgeInsets.only(left: (!isMe && isLTR) ? 30 : 0, right: (!isMe && !isLTR) ? 30 : 0),
                  child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: files.length,
                      padding: files.isNotEmpty ? const EdgeInsets.only(top: Dimensions.paddingSizeSmall) : EdgeInsets.zero,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          mainAxisExtent: 60,
                          crossAxisCount: 2,
                          mainAxisSpacing: Dimensions.paddingSizeExtraSmall,
                          crossAxisSpacing: Dimensions.paddingSizeExtraSmall
                      ),
                      itemBuilder: (context, index){

                        return InkWell(
                          onTap: ()async{
                            final status = await Permission.notification.request();
                            if (kDebugMode) {
                              print("Status is $status");
                            }
                            if(status.isGranted){
                              Directory? directory = Directory('/storage/emulated/0/Download');
                              if (!await directory.exists()){
                                directory = Platform.isAndroid
                                    ? await getExternalStorageDirectory() //FOR ANDROID
                                    : await getApplicationSupportDirectory();
                              }
                              chatProvider.downloadFile(
                                  files[index].path!, directory!.path,
                                  "${directory.path}/${files[index].key}", ""
                                  "${files[index].key}"
                              );
                            }else if(status.isDenied || status.isPermanentlyDenied){
                              await openAppSettings();
                            }
                          },
                          onLongPress: () {
                            // conversationController.toggleOnClickImageAndFile(
                            //     onImageOrFileTimeShowID : widget.conversationData.id!);
                          },
                          child: Container(
                              width: 180,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Theme.of(context).hintColor.withValues(alpha:0.2),
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                              ),
                              child: Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                  child: Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Row(children: [
                                      const Image(image: AssetImage(Images.fileIcon),
                                        height: 30,
                                        width: 30,
                                      ),
                                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),


                                      Expanded(child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [

                                          Text(files[index].key.toString(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: textBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                                          ),

                                          Text("${files[index].size}", style: textRegular.copyWith(
                                              fontSize: Dimensions.fontSizeDefault,
                                              color: Theme.of(context).hintColor),
                                          ),

                                        ],
                                      )),

                                      const _DownloadButtonWidget(),

                                    ]),
                                  )
                              )
                          ),
                        );
                      }
                  ),
                ),
              ) : const SizedBox(),

            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        ]);
      }
    );
  }
}

class _DownloadButtonWidget extends StatelessWidget {

  const _DownloadButtonWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
        child: Icon(Icons.file_download_outlined, color: Theme.of(context).primaryColor),
      ),
    );
  }
}


class _MediaGridWidget extends StatefulWidget {
  final List<Attachment> images;
  final bool isMe;

  const _MediaGridWidget({
    required this.images,
    required this.isMe,

  });

  @override
  State<_MediaGridWidget> createState() => _MediaGridWidgetState();

}

class _MediaGridWidgetState extends State<_MediaGridWidget> {

  List<String>? _videoThumbnails;
  final Map<String, String?> _thumbnailCache = {};


  @override
  void initState() {
    super.initState();
    _generateThumbnails();
  }

  @override
  void didUpdateWidget(covariant _MediaGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images != widget.images) {
      _generateThumbnails();
    }
  }

  Future<void> _generateThumbnails() async {
    final ChatController chatController = Provider.of<ChatController>(context, listen: false);


    // Regenerate the video thumbnails for the updated images
    final List<String> thumbnails = [];
    for (Attachment image in widget.images) {
      if (chatController.isVideoExtension(image.path ?? '')) {
        if (_thumbnailCache.containsKey(image.path)) {
          thumbnails.add(_thumbnailCache[image.path] ?? '');
        } else {

          final thumbnail = await chatController.generateThumbnail(image.path ?? '');
          _thumbnailCache[image.path ?? ''] = thumbnail;

          thumbnails.add(thumbnail ?? '');
        }
      } else {
        thumbnails.add('');
      }
    }

    _videoThumbnails = thumbnails;

    setState(() {
      _videoThumbnails = thumbnails;
    });

  }

  bool _isShowMoreMedia(List<Attachment> images, int index, bool isMe) {
    return images.length > 4 && index ==  (isMe ? 2 : 3);
  }

  @override
  Widget build(BuildContext context) {
    final bool isLtr = Provider.of<LocalizationController>(context, listen: false).isLtr;

    final ChatController chatController = Provider.of<ChatController>(context, listen: false);


    if (widget.images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall, top: 0, left: (!widget.isMe && isLtr) ? 40 : 0, right: (!widget.isMe && !isLtr) ? 40 : 0),
      child: Directionality(
        textDirection: Provider.of<LocalizationController>(context, listen: false).isLtr
            ? widget.isMe ? TextDirection.rtl : TextDirection.ltr : widget.isMe
            ? TextDirection.ltr : TextDirection.rtl,
        child: SizedBox(
          width: MediaQuery.of(context).size.width / 2,
          child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                childAspectRatio: 1,
                crossAxisCount: 2,
                mainAxisSpacing: Dimensions.paddingSizeSmall,
                crossAxisSpacing: Dimensions.paddingSizeSmall,
              ),
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: min(widget.images.length, 4),
              itemBuilder: (BuildContext context, index) {
                return  Stack(children: [
                  InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => MediaViewerScreen(clickedIndex: index, serverMedia: widget.images),
                    )),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      child: Stack(children: [
                        chatController.isVideoExtension(widget.images[index].path ?? '') &&
                            (_videoThumbnails?.isNotEmpty ?? false)
                            ? Image.file(
                          File(_videoThumbnails?[index] ?? ''),
                          fit: BoxFit.cover, height: 200, width: 200,
                          errorBuilder: (_, __, ___)=> const CustomImageWidget(height: 200, width: 200, fit: BoxFit.cover, image: ''),
                        ) : CustomImageWidget(height: 200, width: 200, fit: BoxFit.cover, image: '${widget.images[index].path}'),

                        if(chatController.isVideoExtension(widget.images[index].path ?? '')) Positioned.fill(
                          child: Align(alignment: Alignment.center, child: Container(
                            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.play_arrow, color: Theme.of(context).primaryColor, size: 40),
                          )),
                        ),
                      ]),
                    ),
                  ),

                  if(_isShowMoreMedia(widget.images, index, widget.isMe))
                    Positioned.fill(child: Align(
                      alignment: Alignment.center,
                      child: InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => MediaViewerScreen(clickedIndex: index, serverMedia: widget.images),
                        )),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child:Container(
                              width: MediaQuery.of(context).size.width/4.2, height: MediaQuery.of(context).size.width / 4.2,
                              decoration: BoxDecoration(color: Colors.black54.withValues(alpha:.75), borderRadius: BorderRadius.circular(10)),
                              child: Center(child: Text("+${widget.images.length-3}", style: textRegular.copyWith(color: Colors.white))),
                            )),
                      ),
                    )),
                ]);
              }),
        ),
      ),
    );
  }
}
