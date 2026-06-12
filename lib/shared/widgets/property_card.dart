import 'package:flutter/material.dart';



import '../../core/navigation/app_navigation.dart';

import '../../core/theme/app_colors.dart';

import '../../core/utils/indian_price_formatter.dart';

import '../../core/utils/property_gallery.dart';

import '../../features/property/data/repositories/property_repository.dart';

import '../../features/property/domain/entities/property.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'property_thumbnail.dart';



/// Compact vertical card for horizontal scroll sections (home featured).

class PropertyGridCard extends ConsumerWidget {

  const PropertyGridCard({super.key, required this.property, this.width = 260});



  final Property property;

  final double width;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final resolver = ref.watch(mediaUrlResolverProvider);

    final imageUrl = propertyCardThumbnailUrl(property, resolver);

    final hasVideo = propertyHasVideo(property);



    return SizedBox(

      width: width,

      child: LayoutBuilder(

        builder: (context, constraints) {

          final boundedHeight = constraints.maxHeight.isFinite;

          final body = _CardBody(

            property: property,

            imageUrl: imageUrl,

            hasVideo: hasVideo,

            expandText: boundedHeight,

          );

          return Material(

            color: AppColors.surface,

            elevation: 0,

            shape: RoundedRectangleBorder(

              borderRadius: BorderRadius.circular(16),

              side: const BorderSide(color: AppColors.border),

            ),

            clipBehavior: Clip.antiAlias,

            child: InkWell(

              onTap: () => AppNavigation.openProperty(context, property.id),

              child: boundedHeight

                  ? Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        AspectRatio(

                          aspectRatio: 16 / 10,

                          child: PropertyThumbnail(

                            imageUrl: imageUrl,

                            showVideoBadge: hasVideo,

                            fit: BoxFit.cover,

                          ),

                        ),

                        Expanded(child: body),

                      ],

                    )

                  : Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      mainAxisSize: MainAxisSize.min,

                      children: [

                        AspectRatio(

                          aspectRatio: 16 / 10,

                          child: PropertyThumbnail(

                            imageUrl: imageUrl,

                            showVideoBadge: hasVideo,

                            fit: BoxFit.cover,

                          ),

                        ),

                        body,

                      ],

                    ),

            ),

          );

        },

      ),

    );

  }

}



class _CardBody extends StatelessWidget {

  const _CardBody({

    required this.property,

    required this.imageUrl,

    required this.hasVideo,

    required this.expandText,

  });



  final Property property;

  final String imageUrl;

  final bool hasVideo;

  final bool expandText;



  @override

  Widget build(BuildContext context) {

    final textTheme = Theme.of(context).textTheme;

    final content = Padding(

      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        mainAxisSize: MainAxisSize.min,

        children: [

          Row(

            children: [

              _ListingBadge(

                label: property.listingType == ListingType.sale ? 'BUY' : 'RENT',

              ),

              if (property.isPremium == true) ...[

                const SizedBox(width: 6),

                const _ListingBadge(label: 'PREMIUM', color: AppColors.accent),

              ],

            ],

          ),

          const SizedBox(height: 6),

          Text(

            IndianPriceFormatter.format(property.price),

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: textTheme.titleMedium?.copyWith(

              color: AppColors.primary,

              fontWeight: FontWeight.w800,

              height: 1.15,

            ),

          ),

          const SizedBox(height: 2),

          Text(

            property.title,

            maxLines: 2,

            overflow: TextOverflow.ellipsis,

            style: textTheme.bodyMedium?.copyWith(

              fontWeight: FontWeight.w600,

              height: 1.2,

            ),

          ),

          const SizedBox(height: 4),

          Text(

            '${property.city ?? ''}${property.locality != null ? ', ${property.locality}' : ''}',

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted, height: 1.15),

          ),

          const SizedBox(height: 6),

          Row(

            children: [

              if (property.bedrooms != null) ...[

                const Icon(Icons.bed_outlined, size: 14, color: AppColors.textMuted),

                const SizedBox(width: 4),

                Flexible(

                  child: Text(

                    '${property.bedrooms} BHK',

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: textTheme.labelSmall?.copyWith(height: 1.1),

                  ),

                ),

                const SizedBox(width: 8),

              ],

              if (property.areaSqft != null)

                Flexible(

                  child: Text(

                    '${property.areaSqft!.round()} sq.ft',

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: textTheme.labelSmall?.copyWith(height: 1.1),

                  ),

                ),

            ],

          ),

          if (expandText) const Spacer(),

        ],

      ),

    );

    return content;

  }

}



/// Horizontal list card for search / saved results.

class PropertyListCard extends ConsumerWidget {

  const PropertyListCard({super.key, required this.property});



  final Property property;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final resolver = ref.watch(mediaUrlResolverProvider);

    final imageUrl = propertyCardThumbnailUrl(property, resolver);

    final hasVideo = propertyHasVideo(property);

    final imageWidth = MediaQuery.sizeOf(context).width >= 600 ? 148.0 : 128.0;



    return ConstrainedBox(

      constraints: const BoxConstraints(minHeight: 132, maxHeight: 148),

      child: Material(

        color: AppColors.surface,

        elevation: 0,

        shape: RoundedRectangleBorder(

          borderRadius: BorderRadius.circular(16),

          side: const BorderSide(color: AppColors.border),

        ),

        clipBehavior: Clip.antiAlias,

        child: InkWell(

          onTap: () => AppNavigation.openProperty(context, property.id),

          child: IntrinsicHeight(

            child: Row(

              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [

                SizedBox(

                  width: imageWidth,

                  child: PropertyThumbnail(

                    imageUrl: imageUrl,

                    width: imageWidth,

                    showVideoBadge: hasVideo,

                    fit: BoxFit.cover,

                  ),

                ),

                Expanded(

                  child: Padding(

                    padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [

                        Row(

                          children: [

                            _ListingBadge(

                              label: property.listingType == ListingType.sale ? 'BUY' : 'RENT',

                            ),

                            if (property.isPremium == true) ...[

                              const SizedBox(width: 6),

                              const _ListingBadge(label: 'PREMIUM', color: AppColors.accent),

                            ],

                          ],

                        ),

                        const SizedBox(height: 4),

                        Text(

                          IndianPriceFormatter.format(property.price),

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: Theme.of(context).textTheme.titleSmall?.copyWith(

                                color: AppColors.primary,

                                fontWeight: FontWeight.w800,

                                height: 1.15,

                              ),

                        ),

                        const SizedBox(height: 2),

                        Text(

                          property.title,

                          maxLines: 2,

                          overflow: TextOverflow.ellipsis,

                          style: Theme.of(context).textTheme.bodySmall?.copyWith(

                                fontWeight: FontWeight.w600,

                                height: 1.2,

                              ),

                        ),

                        const SizedBox(height: 4),

                        Text(

                          '${property.city ?? ''}${property.locality != null ? ', ${property.locality}' : ''}',

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: Theme.of(context).textTheme.labelSmall?.copyWith(

                                color: AppColors.textMuted,

                                height: 1.1,

                              ),

                        ),

                      ],

                    ),

                  ),

                ),

              ],

            ),

          ),

        ),

      ),

    );

  }

}



/// Backward-compatible alias.

class PropertyCard extends PropertyGridCard {

  const PropertyCard({super.key, required super.property, super.width, String? imageUrl});

}



class _ListingBadge extends StatelessWidget {

  const _ListingBadge({required this.label, this.color = AppColors.primary});



  final String label;

  final Color color;



  @override

  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),

      decoration: BoxDecoration(

        color: color,

        borderRadius: BorderRadius.circular(6),

      ),

      child: Text(

        label,

        style: const TextStyle(

          color: Colors.white,

          fontSize: 10,

          fontWeight: FontWeight.w700,

          letterSpacing: 0.3,

          height: 1.1,

        ),

      ),

    );

  }

}


