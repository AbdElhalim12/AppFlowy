import { AlignType } from '@/application/collab.type';
import { notify } from '@/components/_shared/notify';
import RightTopActionsToolbar from '@/components/editor/components/block-actions/RightTopActionsToolbar';
import { EditorElementProps, ImageBlockNode } from '@/components/editor/editor.type';
import { copyTextToClipboard } from '@/utils/copy';
import React, { forwardRef, memo, useCallback, useMemo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactEditor, useSelected, useSlateStatic } from 'slate-react';
import ImageEmpty from './ImageEmpty';
import ImageRender from './ImageRender';

export const ImageBlock = memo(
  forwardRef<HTMLDivElement, EditorElementProps<ImageBlockNode>>(({ node, children, className, ...attributes }, ref) => {
    const selected = useSelected();
    const { url, align } = useMemo(() => node.data || {}, [node.data]);
    const containerRef = useRef<HTMLDivElement>(null);
    const editor = useSlateStatic();
    const onFocusNode = useCallback(() => {
      ReactEditor.focus(editor);
      const path = ReactEditor.findPath(editor, node);

      editor.select(path);
    }, [editor, node]);

    const alignCss = useMemo(() => {
      if (!align) return '';

      return align === AlignType.Center ? 'justify-center' : align === AlignType.Right ? 'justify-end' : 'justify-start';
    }, [align]);

    const { t } = useTranslation();
    const [showToolbar, setShowToolbar] = useState(false);

    return (
      <div
        {...attributes}
        ref={containerRef}
        onMouseEnter={() => {
          if (!url) return;
          setShowToolbar(true);
        }}
        onMouseLeave={() => setShowToolbar(false)}
        className={`${className || ''} image-block  cursor-default} relative w-full py-1`}
      >
        <div ref={ref} className={'absolute left-0 top-0 h-full w-full select-none caret-transparent'}>
          {children}
        </div>
        <div contentEditable={false} className={`flex w-full select-none ${url ? '' : 'rounded border'} ${alignCss}`}>
          {url ? (
            <ImageRender selected={selected} node={node} />
          ) : (
            <ImageEmpty node={node} onEscape={onFocusNode} containerRef={containerRef} />
          )}
        </div>
        {showToolbar && (
          <RightTopActionsToolbar
            onCopy={async () => {
              if (!url) return;
              try {
                await copyTextToClipboard(url);
                notify.success(t('publish.copy.imageBlock'));
              } catch (_) {
                // do nothing
              }
            }}
          />
        )}
      </div>
    );
  })
);

export default ImageBlock;
